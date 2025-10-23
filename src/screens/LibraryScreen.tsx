import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  RefreshControl,
  TextInput,
  ActivityIndicator,
  Alert,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { NavigationProp, useNavigation } from '@react-navigation/native';
import readingListService, { ReadingList, BookshelfItem } from '../services/readingList.service';
import { RootStackParamList } from '../navigation/RootNavigator';

type CombinedList = {
  id: string;
  name: string;
  count: number;
  isSystem: boolean;
};

const LibraryScreen: React.FC = () => {
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const [selectedList, setSelectedList] = useState<string>('bookshelf');
  const [readingLists, setReadingLists] = useState<ReadingList[]>([]);
  const [books, setBooks] = useState<BookshelfItem[]>([]);
  const [bookshelfCount, setBookshelfCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [listLoading, setListLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<'recent' | 'title' | 'progress'>('recent');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newListName, setNewListName] = useState('');

  useEffect(() => {
    loadInitialData();
  }, []);

  useEffect(() => {
    if (selectedList === 'bookshelf') {
      loadStarredBooks();
    } else {
      const listId = parseInt(selectedList, 10);
      if (!Number.isNaN(listId)) {
        loadReadingListBooks(listId);
      }
    }
  }, [selectedList]);

  const loadInitialData = useCallback(async () => {
    try {
      setLoading(true);
      await Promise.all([loadReadingLists(), loadStarredBooks()]);
    } finally {
      setLoading(false);
    }
  }, []);

  const loadReadingLists = async () => {
    try {
      const lists = await readingListService.getUserReadingLists();
      setReadingLists(lists);
    } catch (err) {
      console.error('Failed to load reading lists', err);
    }
  };

  const loadStarredBooks = async () => {
    try {
      setListLoading(true);
      const { books: starredBooks } = await readingListService.getStarredBooks({ limit: 200 });
      setBooks(starredBooks);
      setBookshelfCount(starredBooks.length);
    } catch (err) {
      console.error('Failed to load bookshelf', err);
    } finally {
      setListLoading(false);
    }
  };

  const loadReadingListBooks = async (listId: number) => {
    try {
      setListLoading(true);
      const { books: listBooks } = await readingListService.getReadingListDetail(listId, { limit: 200 });
      setBooks(listBooks);
    } catch (err) {
      console.error('Failed to load list books', err);
    } finally {
      setListLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadInitialData();
    setRefreshing(false);
  };

  const handleCreateList = async () => {
    if (!newListName.trim()) {
      Alert.alert('Error', 'Please enter a list name');
      return;
    }

    try {
      await readingListService.createReadingList(newListName.trim());
      setNewListName('');
      setShowCreateModal(false);
      await loadReadingLists();
      Alert.alert('Success', 'Reading list created');
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to create reading list');
    }
  };

  const handleDeleteList = (listId: number, listName: string) => {
    Alert.alert(
      'Delete Reading List',
      `Are you sure you want to delete "${listName}"?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            const success = await readingListService.deleteReadingList(listId);
            if (success) {
              if (selectedList === listId.toString()) {
                setSelectedList('bookshelf');
                await loadStarredBooks();
              }
              await loadReadingLists();
              Alert.alert('Success', 'Reading list deleted');
            }
          },
        },
      ]
    );
  };

  const filteredAndSortedBooks = useMemo(() => {
    const query = searchQuery.toLowerCase();
    let filtered = books.filter((book) => {
      const title = (book.bookTitle || '').toLowerCase();
      const author = (book.author || '').toLowerCase();
      return title.includes(query) || author.includes(query);
    });

    switch (sortBy) {
      case 'recent':
        filtered = filtered.sort((a, b) =>
          new Date(b.lastReadAt || b.addedAt).getTime() -
          new Date(a.lastReadAt || a.addedAt).getTime()
        );
        break;
      case 'title':
        filtered = filtered.sort((a, b) => (a.bookTitle || '').localeCompare(b.bookTitle || ''));
        break;
      case 'progress':
        filtered = filtered.sort((a, b) => (b.progress || 0) - (a.progress || 0));
        break;
      default:
        break;
    }

    return filtered;
  }, [books, searchQuery, sortBy]);

  const stats = useMemo(() => ({
    total: books.length,
    reading: books.filter((b) => (b.progress || 0) > 0 && (b.progress || 0) < 100).length,
    completed: books.filter((b) => (b.progress || 0) === 100).length,
  }), [books]);

  const combinedLists: CombinedList[] = useMemo(() => {
    const userLists = readingLists
      .filter((list) => !list.isSystem)
      .map((list) => ({
        id: list.id.toString(),
        name: list.name,
        count: list.bookCount || 0,
        isSystem: false,
      }));

    return [
      { id: 'bookshelf', name: 'My Bookshelf', count: bookshelfCount, isSystem: true },
      ...userLists,
    ];
  }, [readingLists, bookshelfCount]);

  const navigateToBook = (bookId: number | string) => {
    const numericId = Number(bookId);
    if (!Number.isNaN(numericId)) {
      navigation.navigate('BookDetail', { bookId: numericId });
    }
  };

  const renderBookCard = (item: BookshelfItem) => (
    <TouchableOpacity key={item.id} style={styles.bookCard} activeOpacity={0.85} onPress={() => navigateToBook(item.bookId)}>
      <View style={styles.bookCoverWrapper}>
        {item.bookCover ? (
          <Image source={{ uri: item.bookCover }} style={styles.bookCover} />
        ) : (
          <View style={styles.bookCoverPlaceholder}>
            <Text style={{ fontSize: 24 }}>📚</Text>
          </View>
        )}
      </View>
      <View style={styles.bookInfo}>
        <Text style={styles.bookTitle} numberOfLines={2}>{item.bookTitle || 'Untitled'}</Text>
        <Text style={styles.bookAuthor} numberOfLines={1}>{item.author || 'Unknown Author'}</Text>
        <Text style={styles.chapterInfo}>{getChapterInfo(item)}</Text>

        {item.progress > 0 && item.progress < 100 && (
          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: `${item.progress}%` }]} />
            </View>
            <Text style={styles.progressText}>{item.progress}%</Text>
          </View>
        )}

        {item.progress === 100 && (
          <View style={styles.completedBadge}>
            <Ionicons name="checkmark-circle" size={16} color="#10b981" />
            <Text style={styles.completedText}>Completed</Text>
          </View>
        )}
      </View>
    </TouchableOpacity>
  );

  const getChapterInfo = (book: BookshelfItem) => {
    if (book.currentChapter) {
      return `Chapter ${book.currentChapter.chapter_number}`;
    }
    if (book.lastReadChapter) {
      return `Last read: Ch. ${book.lastReadChapter.chapter_number}`;
    }
    if (book.progress > 0) {
      return `${book.progress}% complete`;
    }
    return 'Not started';
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#6366f1" />
      </View>
    );
  }

  return (
    <View style={styles.screen}>
      <ScrollView
        style={styles.container}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.headerCard}>
          <View style={styles.headerText}>
            <Text style={styles.headerTitle}>My Library</Text>
            <Text style={styles.headerSubtitle}>Track your reading journey across every device.</Text>
          </View>
          <View style={styles.statsRow}>
            <View style={styles.statChip}>
              <Text style={styles.statValue}>{stats.total}</Text>
              <Text style={styles.statLabel}>Books</Text>
            </View>
            <View style={styles.statChip}>
              <Text style={styles.statValue}>{stats.reading}</Text>
              <Text style={styles.statLabel}>Reading</Text>
            </View>
            <View style={styles.statChip}>
              <Text style={styles.statValue}>{stats.completed}</Text>
              <Text style={styles.statLabel}>Completed</Text>
            </View>
          </View>
        </View>

        <View style={styles.listSection}>
          <View style={styles.listHeader}>
            <Text style={styles.sectionTitle}>Reading Lists</Text>
            <TouchableOpacity onPress={() => setShowCreateModal(true)} style={styles.addButton}>
              <Ionicons name="add" size={18} color="#4f46e5" />
              <Text style={styles.addButtonText}>New List</Text>
            </TouchableOpacity>
          </View>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.listChips}
          >
            {combinedLists.map((list) => {
              const active = selectedList === list.id;
              return (
                <TouchableOpacity
                  key={list.id}
                  style={[styles.listChip, active && styles.listChipActive]}
                  onPress={() => setSelectedList(list.id)}
                  activeOpacity={0.85}
                >
                  <Text style={[styles.listChipText, active && styles.listChipTextActive]} numberOfLines={1}>
                    {list.name}
                  </Text>
                  <View style={[styles.listChipBadge, active && styles.listChipBadgeActive]}>
                    <Text style={[styles.listChipBadgeText, active && styles.listChipBadgeTextActive]}>
                      {list.count}
                    </Text>
                  </View>
                  {!list.isSystem && active ? (
                    <TouchableOpacity
                      style={styles.listChipDelete}
                      onPress={() => handleDeleteList(Number(list.id), list.name)}
                      hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}
                    >
                      <Ionicons name="trash-outline" size={16} color="#fff" />
                    </TouchableOpacity>
                  ) : null}
                </TouchableOpacity>
              );
            })}
          </ScrollView>
        </View>

        <View style={styles.toolbar}>
          <View style={styles.searchInputWrapper}>
            <Ionicons name="search" size={18} color="#9ca3af" style={{ marginRight: 8 }} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search in this list"
              value={searchQuery}
              onChangeText={setSearchQuery}
            />
          </View>
          <TouchableOpacity
            style={styles.sortButton}
            onPress={() => {
              const sorts: ('recent' | 'title' | 'progress')[] = ['recent', 'title', 'progress'];
              const currentIndex = sorts.indexOf(sortBy);
              const nextIndex = (currentIndex + 1) % sorts.length;
              setSortBy(sorts[nextIndex]);
            }}
          >
            <Ionicons name="swap-vertical" size={18} color="#4f46e5" />
            <Text style={styles.sortText}>
              {sortBy === 'recent' ? 'Recent' : sortBy === 'title' ? 'Title' : 'Progress'}
            </Text>
          </TouchableOpacity>
        </View>

        {listLoading ? (
          <View style={styles.listLoading}>
            <ActivityIndicator size="small" color="#4f46e5" />
            <Text style={styles.listLoadingText}>Updating {selectedList === 'bookshelf' ? 'bookshelf' : 'list'}…</Text>
          </View>
        ) : null}

        <View style={styles.booksSection}>
          {filteredAndSortedBooks.length === 0 && !listLoading ? (
            <View style={styles.emptyState}>
              <Ionicons name="book-outline" size={56} color="#cbd5f5" />
              <Text style={styles.emptyTitle}>No books in this list</Text>
              <Text style={styles.emptySubtitle}>Add titles to keep track of your reading progress.</Text>
            </View>
          ) : (
            filteredAndSortedBooks.map(renderBookCard)
          )}
        </View>
      </ScrollView>

      <Modal
        visible={showCreateModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowCreateModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Create Reading List</Text>
            <TextInput
              style={styles.modalInput}
              placeholder="List name"
              value={newListName}
              onChangeText={setNewListName}
              autoFocus
            />
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonCancel]}
                onPress={() => {
                  setShowCreateModal(false);
                  setNewListName('');
                }}
              >
                <Text style={styles.modalButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonCreate]}
                onPress={handleCreateList}
              >
                <Text style={[styles.modalButtonText, styles.modalButtonTextCreate]}>Create</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#f5f7ff',
  },
  container: {
    flex: 1,
    paddingHorizontal: 20,
    paddingBottom: 32,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f7ff',
  },
  headerCard: {
    backgroundColor: '#ffffff',
    borderRadius: 20,
    padding: 20,
    marginTop: 20,
    marginBottom: 24,
    shadowColor: '#4f46e5',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 3,
  },
  headerText: {
    marginBottom: 16,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: '#1f2937',
  },
  headerSubtitle: {
    marginTop: 6,
    fontSize: 13,
    color: '#6b7280',
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statChip: {
    flex: 1,
    marginHorizontal: 4,
    backgroundColor: '#f0f4ff',
    borderRadius: 16,
    paddingVertical: 12,
    alignItems: 'center',
  },
  statValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1f2937',
  },
  statLabel: {
    marginTop: 4,
    fontSize: 12,
    color: '#6b7280',
  },
  listSection: {
    marginBottom: 20,
  },
  listHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111827',
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#eef2ff',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
  },
  addButtonText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#4f46e5',
    marginLeft: 6,
  },
  listChips: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingBottom: 4,
  },
  listChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 999,
    backgroundColor: '#eef2ff',
    marginRight: 12,
  },
  listChipActive: {
    backgroundColor: '#4f46e5',
  },
  listChipText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#4f46e5',
  },
  listChipTextActive: {
    color: '#fff',
  },
  listChipBadge: {
    marginLeft: 8,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    backgroundColor: '#dbeafe',
  },
  listChipBadgeActive: {
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  listChipBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#3b82f6',
  },
  listChipBadgeTextActive: {
    color: '#fff',
  },
  listChipDelete: {
    marginLeft: 8,
  },
  toolbar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  searchInputWrapper: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 12,
    paddingHorizontal: 12,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#e5e7eb',
    height: 42,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    color: '#111827',
  },
  sortButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#eef2ff',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 12,
  },
  sortText: {
    marginLeft: 6,
    fontSize: 13,
    fontWeight: '600',
    color: '#4338ca',
  },
  listLoading: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#eef2ff',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 12,
    marginBottom: 16,
  },
  listLoadingText: {
    marginLeft: 10,
    fontSize: 13,
    color: '#4f46e5',
  },
  booksSection: {
    marginBottom: 32,
  },
  bookCard: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 14,
    marginBottom: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 10,
    elevation: 3,
  },
  bookCoverWrapper: {
    width: 72,
    height: 104,
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: '#e0e7ff',
  },
  bookCover: {
    width: '100%',
    height: '100%',
  },
  bookCoverPlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  bookInfo: {
    flex: 1,
    marginLeft: 14,
  },
  bookTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#111827',
  },
  bookAuthor: {
    marginTop: 4,
    fontSize: 13,
    color: '#6b7280',
  },
  chapterInfo: {
    marginTop: 6,
    fontSize: 12,
    color: '#6366f1',
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    gap: 8,
  },
  progressBar: {
    flex: 1,
    height: 6,
    backgroundColor: '#e5e7eb',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#6366f1',
  },
  progressText: {
    fontSize: 12,
    color: '#6b7280',
  },
  completedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
    backgroundColor: '#ecfdf5',
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
  },
  completedText: {
    marginLeft: 4,
    fontSize: 12,
    color: '#10b981',
    fontWeight: '600',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 40,
    backgroundColor: '#fff',
    borderRadius: 16,
  },
  emptyTitle: {
    marginTop: 12,
    fontSize: 16,
    fontWeight: '700',
    color: '#1f2937',
  },
  emptySubtitle: {
    marginTop: 6,
    fontSize: 13,
    color: '#6b7280',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.35)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#fff',
    width: '80%',
    borderRadius: 18,
    padding: 24,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 16,
  },
  modalInput: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#d1d5db',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 14,
    color: '#111827',
    marginBottom: 20,
  },
  modalButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  modalButton: {
    flex: 1,
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: 'center',
  },
  modalButtonCancel: {
    backgroundColor: '#f3f4f6',
  },
  modalButtonCreate: {
    backgroundColor: '#4f46e5',
  },
  modalButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#4b5563',
  },
  modalButtonTextCreate: {
    color: '#fff',
  },
});

export default LibraryScreen;
