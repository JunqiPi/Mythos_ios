import React, { useState, useEffect, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Image,
  RefreshControl,
  TextInput,
  ScrollView,
  Alert,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import readingListService, { ReadingList, BookshelfItem } from '../services/readingList.service';

export default function LibraryScreen() {
  const [selectedList, setSelectedList] = useState<string>('bookshelf');
  const [readingLists, setReadingLists] = useState<ReadingList[]>([]);
  const [books, setBooks] = useState<BookshelfItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<'recent' | 'title' | 'progress'>('recent');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newListName, setNewListName] = useState('');

  // Load initial data
  useEffect(() => {
    loadData();
  }, []);

  // Load data when selected list changes
  useEffect(() => {
    if (selectedList === 'bookshelf') {
      loadStarredBooks();
    } else {
      loadReadingListBooks(parseInt(selectedList));
    }
  }, [selectedList]);

  const loadData = async () => {
    setLoading(true);
    await Promise.all([
      loadReadingLists(),
      loadStarredBooks(),
    ]);
    setLoading(false);
  };

  const loadReadingLists = async () => {
    const lists = await readingListService.getUserReadingLists();
    setReadingLists(lists);
  };

  const loadStarredBooks = async () => {
    const { books: starredBooks } = await readingListService.getStarredBooks({ limit: 100 });
    setBooks(starredBooks);
  };

  const loadReadingListBooks = async (listId: number) => {
    setLoading(true);
    const { books: listBooks } = await readingListService.getReadingListDetail(listId, { limit: 100 });
    setBooks(listBooks);
    setLoading(false);
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
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
              }
              await loadReadingLists();
              Alert.alert('Success', 'Reading list deleted');
            }
          },
        },
      ]
    );
  };

  // Filter and sort books
  const filteredAndSortedBooks = useMemo(() => {
    let filtered = books.filter(book =>
      (book.bookTitle || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (book.author || '').toLowerCase().includes(searchQuery.toLowerCase())
    );

    switch (sortBy) {
      case 'recent':
        filtered.sort((a, b) =>
          new Date(b.lastReadAt || b.addedAt).getTime() -
          new Date(a.lastReadAt || a.addedAt).getTime()
        );
        break;
      case 'title':
        filtered.sort((a, b) => (a.bookTitle || '').localeCompare(b.bookTitle || ''));
        break;
      case 'progress':
        filtered.sort((a, b) => b.progress - a.progress);
        break;
    }

    return filtered;
  }, [books, searchQuery, sortBy]);

  // Stats
  const stats = useMemo(() => {
    return {
      total: books.length,
      reading: books.filter(b => (b.progress || 0) > 0 && (b.progress || 0) < 100).length,
      completed: books.filter(b => (b.progress || 0) === 100).length,
    };
  }, [books]);

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

  const renderBook = ({ item }: { item: BookshelfItem }) => (
    <TouchableOpacity style={styles.bookCard}>
      <Image
        source={{ uri: item.bookCover || 'https://via.placeholder.com/120x160' }}
        style={styles.bookCover}
      />
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

  const renderListItem = (list: ReadingList) => (
    <TouchableOpacity
      key={list.id}
      style={[
        styles.listItem,
        selectedList === list.id.toString() && styles.listItemActive
      ]}
      onPress={() => setSelectedList(list.id.toString())}
      onLongPress={() => !list.isSystem && handleDeleteList(list.id, list.name)}
    >
      <View style={styles.listItemLeft}>
        <Ionicons
          name={list.isSystem ? 'bookmark' : 'folder'}
          size={20}
          color={selectedList === list.id.toString() ? '#fff' : '#6b7280'}
        />
        <Text
          style={[
            styles.listItemText,
            selectedList === list.id.toString() && styles.listItemTextActive
          ]}
          numberOfLines={1}
        >
          {list.name}
        </Text>
      </View>
      <View style={styles.listItemRight}>
        <View style={[
          styles.countBadge,
          selectedList === list.id.toString() && styles.countBadgeActive
        ]}>
          <Text style={[
            styles.countText,
            selectedList === list.id.toString() && styles.countTextActive
          ]}>
            {list.bookCount || 0}
          </Text>
        </View>
        {!list.isSystem && selectedList === list.id.toString() && (
          <TouchableOpacity
            onPress={() => handleDeleteList(list.id, list.name)}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <Ionicons name="trash-outline" size={16} color="#fff" />
          </TouchableOpacity>
        )}
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>My Library</Text>
        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>{stats.total}</Text>
            <Text style={styles.statLabel}>Books</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>{stats.reading}</Text>
            <Text style={styles.statLabel}>Reading</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>{stats.completed}</Text>
            <Text style={styles.statLabel}>Completed</Text>
          </View>
        </View>
      </View>

      <View style={styles.content}>
        {/* Left Sidebar - Reading Lists */}
        <ScrollView style={styles.sidebar} showsVerticalScrollIndicator={false}>
          {/* My Bookshelf */}
          <TouchableOpacity
            style={[
              styles.listItem,
              selectedList === 'bookshelf' && styles.listItemActive
            ]}
            onPress={() => setSelectedList('bookshelf')}
          >
            <View style={styles.listItemLeft}>
              <Ionicons
                name="bookmark"
                size={20}
                color={selectedList === 'bookshelf' ? '#fff' : '#6b7280'}
              />
              <Text
                style={[
                  styles.listItemText,
                  selectedList === 'bookshelf' && styles.listItemTextActive
                ]}
              >
                My Bookshelf
              </Text>
            </View>
            <View style={[
              styles.countBadge,
              selectedList === 'bookshelf' && styles.countBadgeActive
            ]}>
              <Text style={[
                styles.countText,
                selectedList === 'bookshelf' && styles.countTextActive
              ]}>
                {stats.total}
              </Text>
            </View>
          </TouchableOpacity>

          {/* Reading Lists Header */}
          <View style={styles.sidebarHeader}>
            <Text style={styles.sidebarTitle}>Reading Lists</Text>
            <TouchableOpacity onPress={() => setShowCreateModal(true)}>
              <Ionicons name="add-circle-outline" size={24} color="#6366f1" />
            </TouchableOpacity>
          </View>

          {/* Reading Lists */}
          {readingLists.filter(list => !list.isSystem).map(renderListItem)}
        </ScrollView>

        {/* Right Content - Books */}
        <View style={styles.mainContent}>
          {/* Search and Sort */}
          <View style={styles.toolbar}>
            <View style={styles.searchContainer}>
              <Ionicons name="search" size={20} color="#6b7280" style={styles.searchIcon} />
              <TextInput
                style={styles.searchInput}
                placeholder="Search books..."
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
              <Ionicons name="swap-vertical" size={20} color="#6366f1" />
              <Text style={styles.sortText}>
                {sortBy === 'recent' ? 'Recent' : sortBy === 'title' ? 'Title' : 'Progress'}
              </Text>
            </TouchableOpacity>
          </View>

          {/* Books List */}
          <FlatList
            data={filteredAndSortedBooks}
            renderItem={renderBook}
            keyExtractor={(item) => item.id.toString()}
            contentContainerStyle={styles.booksList}
            showsVerticalScrollIndicator={false}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
            }
            ListEmptyComponent={
              <View style={styles.emptyContainer}>
                <Ionicons name="book-outline" size={64} color="#d1d5db" />
                <Text style={styles.emptyText}>No books in this list</Text>
                <Text style={styles.emptySubtext}>
                  Start adding books to build your library
                </Text>
              </View>
            }
          />
        </View>
      </View>

      {/* Create List Modal */}
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
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9fafb',
  },
  header: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 16,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1f2937',
  },
  statLabel: {
    fontSize: 12,
    color: '#6b7280',
    marginTop: 4,
  },
  content: {
    flex: 1,
    flexDirection: 'row',
  },
  sidebar: {
    width: 200,
    backgroundColor: '#fff',
    borderRightWidth: 1,
    borderRightColor: '#e5e7eb',
    paddingVertical: 16,
  },
  sidebarHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginTop: 8,
  },
  sidebarTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6b7280',
  },
  listItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginHorizontal: 8,
    marginVertical: 2,
    borderRadius: 8,
  },
  listItemActive: {
    backgroundColor: '#6366f1',
  },
  listItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    marginRight: 8,
  },
  listItemText: {
    fontSize: 14,
    color: '#1f2937',
    marginLeft: 12,
    flex: 1,
  },
  listItemTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  listItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  countBadge: {
    backgroundColor: '#e5e7eb',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 12,
    minWidth: 28,
    alignItems: 'center',
  },
  countBadgeActive: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  countText: {
    fontSize: 12,
    color: '#6b7280',
    fontWeight: '600',
  },
  countTextActive: {
    color: '#fff',
  },
  mainContent: {
    flex: 1,
  },
  toolbar: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
    gap: 12,
  },
  searchContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f3f4f6',
    borderRadius: 8,
    paddingHorizontal: 12,
  },
  searchIcon: {
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    height: 40,
    fontSize: 14,
    color: '#1f2937',
  },
  sortButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f3f4f6',
    paddingHorizontal: 12,
    borderRadius: 8,
    gap: 6,
  },
  sortText: {
    fontSize: 14,
    color: '#6366f1',
    fontWeight: '500',
  },
  booksList: {
    padding: 16,
  },
  bookCard: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 12,
    marginBottom: 12,
    padding: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  bookCover: {
    width: 80,
    height: 120,
    borderRadius: 8,
    backgroundColor: '#e5e7eb',
  },
  bookInfo: {
    flex: 1,
    marginLeft: 12,
    justifyContent: 'space-between',
  },
  bookTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 4,
  },
  bookAuthor: {
    fontSize: 14,
    color: '#6b7280',
    marginBottom: 8,
  },
  chapterInfo: {
    fontSize: 12,
    color: '#6366f1',
    marginBottom: 8,
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
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
    fontWeight: '600',
  },
  completedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  completedText: {
    fontSize: 12,
    color: '#10b981',
    fontWeight: '600',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#9ca3af',
    marginTop: 16,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#9ca3af',
    marginTop: 8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
    width: '80%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 16,
  },
  modalInput: {
    borderWidth: 1,
    borderColor: '#e5e7eb',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
    marginBottom: 24,
  },
  modalButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  modalButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  modalButtonCancel: {
    backgroundColor: '#f3f4f6',
  },
  modalButtonCreate: {
    backgroundColor: '#6366f1',
  },
  modalButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#6b7280',
  },
  modalButtonTextCreate: {
    color: '#fff',
  },
});
