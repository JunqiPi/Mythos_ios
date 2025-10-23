import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { NavigationProp, RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import bookService, { Book } from '../services/book.service';
import interactionService, { BookInteractionState } from '../services/interaction.service';
import { RootStackParamList } from '../navigation/RootNavigator';

type BookDetailScreenRouteProp = RouteProp<RootStackParamList, 'BookDetail'>;

const BookDetailScreen: React.FC = () => {
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const route = useRoute<BookDetailScreenRouteProp>();
  const { bookId } = route.params;

  const [book, setBook] = useState<Book | null>(null);
  const [interaction, setInteraction] = useState<BookInteractionState | null>(null);
  const [loading, setLoading] = useState(true);
  const [togglingLike, setTogglingLike] = useState(false);
  const [togglingStar, setTogglingStar] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const numericBookId = useMemo(() => Number(bookId), [bookId]);

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const [bookResponse, interactionResponse] = await Promise.all([
        bookService.getBookById(String(bookId)),
        interactionService.getBookInteractions(numericBookId).catch(() => null),
      ]);

      setBook(bookResponse);
      if (interactionResponse) {
        setInteraction(interactionResponse);
      } else {
        setInteraction({ book_id: numericBookId, liked: false, starred: false, following_author: false });
      }
    } catch (err) {
      console.error('Failed to load book detail', err);
      setError('Unable to load book details right now.');
    } finally {
      setLoading(false);
    }
  }, [bookId, numericBookId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleToggleLike = async () => {
    if (!interaction) return;
    try {
      setTogglingLike(true);
      const response = await interactionService.toggleBookLike(numericBookId);
      setInteraction((prev) => (prev ? { ...prev, liked: response.liked } : prev));
      setBook((prev) => (prev ? { ...prev, like_count: response.like_count } : prev));
    } catch (err) {
      console.error('Failed to toggle like', err);
      Alert.alert('Error', 'Could not update like status. Please try again.');
    } finally {
      setTogglingLike(false);
    }
  };

  const handleToggleStar = async () => {
    if (!interaction) return;
    try {
      setTogglingStar(true);
      const response = await interactionService.toggleBookStar(numericBookId);
      setInteraction((prev) => (prev ? { ...prev, starred: response.starred } : prev));
      setBook((prev) => (prev ? { ...prev, starred_count: response.star_count } : prev));
    } catch (err) {
      console.error('Failed to toggle star', err);
      Alert.alert('Error', 'Could not update bookshelf status. Please try again.');
    } finally {
      setTogglingStar(false);
    }
  };

  const handleStartReading = () => {
    navigation.navigate('Reader', { bookId: numericBookId });
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#4f46e5" />
      </View>
    );
  }

  if (error || !book) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.errorText}>{error ?? 'Book not found.'}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={loadData}>
          <Text style={styles.retryText}>Try Again</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const statBlocks = [
    { label: 'Reads', value: book.read_count },
    { label: 'Likes', value: book.like_count },
    { label: 'Favorites', value: book.starred_count },
    { label: 'Gems', value: book.total_gem_count ?? 0 },
  ];

  const tagNames = book.tagNames && book.tagNames.length > 0
    ? book.tagNames
    : book.tags?.map((tag) => String(tag));

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.heroRow}>
        <View style={styles.coverWrapper}>
          {book.cover_url ? (
            <Image source={{ uri: book.cover_url }} style={styles.cover} />
          ) : (
            <View style={styles.coverPlaceholder}>
              <Text style={styles.coverPlaceholderText}>📚</Text>
            </View>
          )}
        </View>
        <View style={styles.heroInfo}>
          <Text style={styles.bookTitle}>{book.title}</Text>
          <Text style={styles.authorName}>by {book.user?.username ?? 'Unknown Author'}</Text>
          <TouchableOpacity style={styles.readButton} onPress={handleStartReading}>
            <Ionicons name="book-outline" size={18} color="#fff" style={{ marginRight: 6 }} />
            <Text style={styles.readButtonText}>Start Reading</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.actionRow}>
        <TouchableOpacity
          style={[styles.actionButton, interaction?.liked && styles.actionButtonActive]}
          onPress={handleToggleLike}
          disabled={togglingLike}
        >
          <Ionicons
            name={interaction?.liked ? 'heart' : 'heart-outline'}
            size={18}
            color={interaction?.liked ? '#ef4444' : '#4f46e5'}
            style={{ marginRight: 6 }}
          />
          <Text style={[styles.actionButtonText, interaction?.liked && styles.actionButtonTextActive]}>
            {togglingLike ? 'Updating…' : 'Like'}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.actionButton, interaction?.starred && styles.actionButtonActive]}
          onPress={handleToggleStar}
          disabled={togglingStar}
        >
          <Ionicons
            name={interaction?.starred ? 'bookmark' : 'bookmark-outline'}
            size={18}
            color={interaction?.starred ? '#f97316' : '#4f46e5'}
            style={{ marginRight: 6 }}
          />
          <Text style={[styles.actionButtonText, interaction?.starred && styles.actionButtonTextActive]}>
            {togglingStar ? 'Updating…' : 'Bookshelf'}
          </Text>
        </TouchableOpacity>
      </View>

      <View style={styles.statsCard}>
        {statBlocks.map((block) => (
          <View key={block.label} style={styles.statBlock}>
            <Text style={styles.statValue}>{(block.value ?? 0).toLocaleString()}</Text>
            <Text style={styles.statLabel}>{block.label}</Text>
          </View>
        ))}
      </View>

      {tagNames && tagNames.length > 0 ? (
        <View style={styles.tagContainer}>
          {tagNames.map((tag) => (
            <View key={tag} style={styles.tagChip}>
              <Text style={styles.tagText}>{tag}</Text>
            </View>
          ))}
        </View>
      ) : null}

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Synopsis</Text>
        <Text style={styles.sectionBody}>
          {book.description || 'No synopsis available yet.'}
        </Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Book Details</Text>
        <View style={styles.detailRow}>
          <Text style={styles.detailLabel}>Category</Text>
          <Text style={styles.detailValue}>{book.categoryName || 'Unknown'}</Text>
        </View>
        <View style={styles.detailRow}>
          <Text style={styles.detailLabel}>Word Count</Text>
          <Text style={styles.detailValue}>{(book.word_number || 0).toLocaleString()} words</Text>
        </View>
        <View style={styles.detailRow}>
          <Text style={styles.detailLabel}>Updated</Text>
          <Text style={styles.detailValue}>{new Date(book.updated_at).toLocaleString()}</Text>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 20,
    backgroundColor: '#f8f9ff',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8f9ff',
  },
  errorText: {
    fontSize: 14,
    color: '#ef4444',
    marginBottom: 12,
  },
  retryButton: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    backgroundColor: '#4f46e5',
    borderRadius: 999,
  },
  retryText: {
    color: '#fff',
    fontWeight: '600',
  },
  heroRow: {
    flexDirection: 'row',
    marginBottom: 24,
  },
  coverWrapper: {
    width: 120,
    height: 168,
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: '#e0e7ff',
  },
  cover: {
    width: '100%',
    height: '100%',
  },
  coverPlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  coverPlaceholderText: {
    fontSize: 32,
  },
  heroInfo: {
    flex: 1,
    marginLeft: 16,
    justifyContent: 'space-between',
  },
  bookTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
  },
  authorName: {
    fontSize: 14,
    color: '#4b5563',
    marginTop: 4,
  },
  readButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#4f46e5',
    alignSelf: 'flex-start',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 999,
  },
  readButtonText: {
    color: '#fff',
    fontWeight: '700',
  },
  actionRow: {
    flexDirection: 'row',
    marginBottom: 20,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: '#4f46e5',
    marginRight: 12,
  },
  actionButtonActive: {
    backgroundColor: '#eef2ff',
  },
  actionButtonText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#4f46e5',
  },
  actionButtonTextActive: {
    color: '#4338ca',
  },
  statsCard: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 12,
    marginBottom: 20,
    justifyContent: 'space-between',
  },
  statBlock: {
    alignItems: 'center',
    flex: 1,
  },
  statValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#1f2937',
  },
  statLabel: {
    marginTop: 4,
    fontSize: 12,
    color: '#6b7280',
  },
  tagContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 24,
  },
  tagChip: {
    backgroundColor: '#e0e7ff',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    marginRight: 8,
    marginBottom: 8,
  },
  tagText: {
    fontSize: 12,
    color: '#4338ca',
    fontWeight: '600',
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 8,
  },
  sectionBody: {
    fontSize: 13,
    lineHeight: 20,
    color: '#4b5563',
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#e5e7eb',
  },
  detailLabel: {
    fontSize: 13,
    color: '#6b7280',
  },
  detailValue: {
    fontSize: 13,
    fontWeight: '600',
    color: '#111827',
  },
});

export default BookDetailScreen;
