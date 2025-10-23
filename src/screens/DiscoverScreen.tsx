import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  View,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
  RefreshControl,
  Text,
  TouchableOpacity,
  TextInput,
  Image,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { NavigationProp, useNavigation } from '@react-navigation/native';
import bookService, { Book, FrontPageBooksResponse } from '../services/book.service';
import rankingService, { RankingItem } from '../services/ranking.service';
import DiscoverHero from '../components/discover/DiscoverHero';
import SectionHeader from '../components/discover/SectionHeader';
import HorizontalBookList from '../components/discover/HorizontalBookList';
import RankingPreviewList from '../components/discover/RankingPreviewList';
import { PreviewBook } from '../components/discover/BookPreviewCard';
import { RootStackParamList } from '../navigation/RootNavigator';

const DISCOVER_TABS = [
  { key: 'newest', label: 'Newest', sort_by: 'created_at', sort_direction: 'desc' as const },
  { key: 'popular', label: 'Popular', sort_by: 'read_count', sort_direction: 'desc' as const },
  { key: 'topRated', label: 'Top Rated', sort_by: 'starred_count', sort_direction: 'desc' as const },
  { key: 'trending', label: 'Trending', sort_by: 'like_count', sort_direction: 'desc' as const },
];

const truncate = (value?: string | null, max = 140) => {
  if (!value) return undefined;
  return value.length > max ? `${value.slice(0, max - 1)}…` : value;
};

const mapBookToPreview = (book: Book, extras: Partial<PreviewBook> = {}): PreviewBook => ({
  id: String(book.id ?? book.title),
  title: book.title,
  author: book.user?.username,
  coverUrl: book.cover_url,
  description: book.description,
  ...extras,
});

const extractHeroFromFrontPage = (
  response: FrontPageBooksResponse | null,
): {
  hero: PreviewBook | null;
  editorPicks: PreviewBook[];
  hotRecommendations: PreviewBook[];
} => {
  if (!response) {
    return { hero: null, editorPicks: [], hotRecommendations: [] };
  }

  const editorPicksRaw = response.editor_picks || [];
  const hotRaw = response.hot_recommendations || [];

  const editorPreviews = editorPicksRaw.map((book, index) =>
    mapBookToPreview(book, { badge: index === 0 ? "Editor's Pick" : undefined }),
  );

  const hotPreviews = hotRaw.map((book) => mapBookToPreview(book, { badge: 'Hot' }));

  const hero = editorPreviews.length > 0 ? editorPreviews[0] : hotPreviews[0] || null;
  const remainingEditors = hero ? editorPreviews.slice(1) : editorPreviews;

  return {
    hero,
    editorPicks: remainingEditors,
    hotRecommendations: hotPreviews,
  };
};

export default function DiscoverScreen() {
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [heroBook, setHeroBook] = useState<PreviewBook | null>(null);
  const [editorPicks, setEditorPicks] = useState<PreviewBook[]>([]);
  const [hotRecommendations, setHotRecommendations] = useState<PreviewBook[]>([]);
  const [tabBooks, setTabBooks] = useState<Record<string, PreviewBook[]>>({});
  const [activeTab, setActiveTab] = useState<string>(DISCOVER_TABS[0].key);
  const [monthlyRanking, setMonthlyRanking] = useState<RankingItem[]>([]);
  const [monthlyRankingError, setMonthlyRankingError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<Book[]>([]);
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState<string | null>(null);
  const [searchTouched, setSearchTouched] = useState(false);

  const loadDiscoverFeed = useCallback(async (isRefresh = false) => {
    try {
      if (isRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }
      setError(null);

      const [frontPage, newest, popular, topRated, trending] = await Promise.all([
        bookService.getFrontPageBooks(),
        bookService.getBooks({ sort_by: 'created_at', sort_direction: 'desc', limit: 8 }),
        bookService.getBooks({ sort_by: 'read_count', sort_direction: 'desc', limit: 8 }),
        bookService.getBooks({ sort_by: 'starred_count', sort_direction: 'desc', limit: 8 }),
        bookService.getBooks({ sort_by: 'like_count', sort_direction: 'desc', limit: 8 }),
      ]);

      const { hero, editorPicks: editorList, hotRecommendations: hotList } =
        extractHeroFromFrontPage(frontPage);

      setHeroBook(hero);
      setEditorPicks(editorList);
      setHotRecommendations(hotList);

      setTabBooks({
        newest: (newest.data || []).map((book) => mapBookToPreview(book)),
        popular: (popular.data || []).map((book) => mapBookToPreview(book)),
        topRated: (topRated.data || []).map((book) => mapBookToPreview(book)),
        trending: (trending.data || []).map((book) => mapBookToPreview(book)),
      });

      try {
        const monthly = await rankingService.getBookRankings({
          type: 'monthly',
          metric: 'gems',
          page_size: 5,
        });
        const mappedMonthly = (monthly.data || []).map((item, index) => ({
          ...item,
          rank: index + 1,
        }));
        setMonthlyRanking(mappedMonthly);
        setMonthlyRankingError(null);
      } catch (rankingError) {
        console.warn('Failed to fetch monthly ranking.', rankingError);
        setMonthlyRanking([]);
        setMonthlyRankingError('Unable to load monthly ranking at the moment.');
      }
    } catch (err) {
      console.error('Failed to load discover feed', err);
      setError('Unable to load discover feed. Pull to refresh.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadDiscoverFeed();
  }, [loadDiscoverFeed]);

  const handleRefresh = useCallback(() => {
    loadDiscoverFeed(true);
  }, [loadDiscoverFeed]);

  const handleSearch = useCallback(async () => {
    const query = searchQuery.trim();
    if (!query) {
      setSearchResults([]);
      setSearchError(null);
      setSearchTouched(false);
      return;
    }

    try {
      setSearching(true);
      setSearchTouched(true);
      setSearchError(null);

      const response = await bookService.searchBooks(query, 1, 10);
      const booksArray = Array.isArray((response as any)?.data?.books)
        ? (response as any).data.books as Book[]
        : Array.isArray(response.data)
          ? (response.data as unknown as Book[])
          : [];
      setSearchResults(booksArray);
    } catch (err) {
      console.error('Search failed', err);
      setSearchError('Unable to complete search. Try again later.');
      setSearchResults([]);
    } finally {
      setSearching(false);
    }
  }, [searchQuery]);

  const openBookDetail = useCallback((id: string) => {
    const numericId = Number(id);
    if (!Number.isNaN(numericId)) {
      navigation.navigate('BookDetail', { bookId: numericId });
    }
  }, [navigation]);

  const handleBookPress = useCallback((book: PreviewBook) => {
    openBookDetail(book.id);
  }, [openBookDetail]);

  const handleRankingPress = useCallback((item: RankingItem) => {
    const idValue = item.book?.id;
    if (idValue !== undefined) {
      openBookDetail(String(idValue));
    }
  }, [openBookDetail]);

  const currentTabBooks = useMemo(() => tabBooks[activeTab] || [], [tabBooks, activeTab]);

  if (loading && !refreshing) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#4f46e5" />
        <Text style={styles.loadingText}>Curating your next adventure…</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={['#4f46e5']}
            tintColor="#4f46e5"
          />
        }
      >
        {error ? (
          <View style={styles.errorBanner}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        <View style={styles.searchContainer}>
          <View style={styles.searchInputWrapper}>
            <Ionicons name="search" size={18} color="#9ca3af" style={styles.searchIcon} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search books, authors, or tags"
              value={searchQuery}
              onChangeText={setSearchQuery}
              onSubmitEditing={handleSearch}
              returnKeyType="search"
            />
            {searchQuery.length > 0 ? (
              <TouchableOpacity
                onPress={() => {
                  setSearchQuery('');
                  setSearchResults([]);
                  setSearchError(null);
                  setSearchTouched(false);
                }}
                style={styles.clearButton}
              >
                <Ionicons name="close-circle" size={18} color="#cbd5f5" />
              </TouchableOpacity>
            ) : null}
          </View>
          <TouchableOpacity
            style={styles.searchButton}
            onPress={handleSearch}
            disabled={searching}
          >
            <Text style={styles.searchButtonText}>{searching ? 'Searching…' : 'Search'}</Text>
          </TouchableOpacity>
        </View>

        {searchTouched ? (
          <View style={styles.searchResultsCard}>
            <View style={styles.searchResultsHeader}>
              <Text style={styles.searchResultsTitle}>Search Results</Text>
              <Text style={styles.searchResultsMeta}>
                {searching ? 'Finding stories for you…' : `${searchResults.length} matches`}
              </Text>
            </View>
            {searchError ? (
              <Text style={styles.searchError}>{searchError}</Text>
            ) : searchResults.length === 0 && !searching ? (
              <Text style={styles.searchEmpty}>No titles found. Try a different keyword.</Text>
            ) : (
              searchResults.map((result) => (
                <TouchableOpacity
                  key={result.id}
                  style={styles.searchResultRow}
                  activeOpacity={0.8}
                  onPress={() => openBookDetail(String(result.id))}
                >
                  <View style={styles.searchResultCover}>
                    {result.cover_url ? (
                      <Image source={{ uri: result.cover_url }} style={styles.searchCoverImage} />
                    ) : (
                      <View style={styles.searchCoverPlaceholder}>
                        <Text style={{ fontSize: 16 }}>📘</Text>
                      </View>
                    )}
                  </View>
                  <View style={styles.searchResultInfo}>
                    <Text style={styles.searchResultTitle} numberOfLines={1}>
                      {result.title}
                    </Text>
                    <Text style={styles.searchResultMeta} numberOfLines={1}>
                      {result.user?.username ?? 'Unknown Author'}
                    </Text>
                  </View>
                  <Ionicons name="chevron-forward" size={18} color="#cbd5f5" />
                </TouchableOpacity>
              ))
            )}
          </View>
        ) : null}

        <DiscoverHero
          book={heroBook}
          title="Center of the World"
          subtitle={truncate(heroBook?.description)}
          onPress={handleBookPress}
        />

        <SectionHeader title="Editor's Picks" subtitle="Our editorial team’s must-read lineup" />
        <HorizontalBookList data={editorPicks} onPressItem={handleBookPress} />

        <SectionHeader title="Hot Recommendations" subtitle="Readers can’t stop talking about these" />
        <HorizontalBookList data={hotRecommendations} onPressItem={handleBookPress} />

        <SectionHeader
          title="Monthly Ranking"
          subtitle="Top gems collected this month"
          actionLabel="View Rankings"
          onPressAction={() => navigation.getParent()?.navigate('Ranking' as never)}
        />
        {monthlyRanking.length > 0 ? (
          <RankingPreviewList
            data={monthlyRanking}
            metricLabel="Gems"
            onItemPress={handleRankingPress}
          />
        ) : (
          <View style={styles.rankingEmpty}>
            <Text style={styles.emptyMessage}>No monthly ranking data yet.</Text>
            {monthlyRankingError ? (
              <Text style={styles.rankingEmptyHint}>{monthlyRankingError}</Text>
            ) : null}
          </View>
        )}

        <SectionHeader
          title="Find Your Next Great Read"
          subtitle="Curated shelves to fit every mood"
        />

        <View style={styles.tabRow}>
          {DISCOVER_TABS.map((tab) => {
            const isActive = tab.key === activeTab;
            return (
              <TouchableOpacity
                key={tab.key}
                style={[styles.tabButton, isActive && styles.tabButtonActive]}
                onPress={() => setActiveTab(tab.key)}
                activeOpacity={0.85}
              >
                <Text style={[styles.tabLabel, isActive && styles.tabLabelActive]}>{tab.label}</Text>
              </TouchableOpacity>
            );
          })}
        </View>

        {currentTabBooks.length > 0 ? (
          <HorizontalBookList data={currentTabBooks} onPressItem={handleBookPress} />
        ) : (
          <Text style={styles.emptyMessage}>No books yet. Pull to refresh.</Text>
        )}

      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5fb',
  },
  scrollContent: {
    paddingTop: 24,
    paddingBottom: 48,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5fb',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 15,
    color: '#6b7280',
  },
  errorBanner: {
    marginHorizontal: 20,
    marginBottom: 16,
    padding: 12,
    borderRadius: 14,
    backgroundColor: '#fee2e2',
  },
  errorText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#b91c1c',
  },
  searchContainer: {
    marginHorizontal: 20,
    marginBottom: 20,
    flexDirection: 'row',
    alignItems: 'center',
  },
  searchInputWrapper: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginRight: 12,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#e5e7eb',
  },
  searchIcon: {
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    color: '#111827',
  },
  clearButton: {
    marginLeft: 8,
  },
  searchButton: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#4f46e5',
    borderRadius: 12,
  },
  searchButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  searchResultsCard: {
    marginHorizontal: 20,
    marginBottom: 24,
    backgroundColor: '#fff',
    borderRadius: 16,
    paddingVertical: 12,
  },
  searchResultsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    marginBottom: 8,
  },
  searchResultsTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111827',
  },
  searchResultsMeta: {
    fontSize: 12,
    color: '#6b7280',
  },
  searchError: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    color: '#ef4444',
    fontSize: 13,
  },
  searchEmpty: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    color: '#6b7280',
    fontSize: 13,
  },
  searchResultRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#eef2ff',
  },
  searchResultCover: {
    width: 46,
    height: 64,
    borderRadius: 10,
    overflow: 'hidden',
    backgroundColor: '#e0e7ff',
    marginRight: 12,
  },
  searchCoverImage: {
    width: '100%',
    height: '100%',
  },
  searchCoverPlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  searchResultInfo: {
    flex: 1,
  },
  searchResultTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111827',
  },
  searchResultMeta: {
    marginTop: 4,
    fontSize: 12,
    color: '#6b7280',
  },
  tabRow: {
    flexDirection: 'row',
    backgroundColor: '#ede9fe',
    borderRadius: 999,
    marginHorizontal: 20,
    padding: 4,
    marginBottom: 16,
  },
  tabButton: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 999,
    alignItems: 'center',
  },
  tabButtonActive: {
    backgroundColor: '#4f46e5',
    shadowColor: '#4338ca',
    shadowOpacity: 0.15,
    shadowRadius: 6,
    elevation: 3,
  },
  tabLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: '#4338ca',
  },
  tabLabelActive: {
    color: '#fff',
  },
  emptyMessage: {
    marginHorizontal: 20,
    marginBottom: 24,
    fontSize: 13,
    textAlign: 'center',
    color: '#6b7280',
  },
  rankingEmpty: {
    marginHorizontal: 20,
    marginBottom: 24,
    paddingVertical: 12,
    alignItems: 'center',
  },
  rankingEmptyHint: {
    marginTop: 6,
    fontSize: 12,
    color: '#9ca3af',
    textAlign: 'center',
  },
});
