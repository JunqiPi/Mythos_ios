import apiService from './api.service';

export interface ReadingList {
  id: number;
  name: string;
  description?: string;
  coverUrl?: string;
  isPublic: boolean;
  isSystem: boolean;
  userId: number;
  bookCount?: number;
  createdAt: string;
  updatedAt: string;
}

export interface BookshelfItem {
  id: number;
  bookId: number;
  bookTitle: string;
  bookCover: string;
  author: string;
  lastReadAt: string;
  progress: number;
  addedAt: string;
  status: number;
  wordCount: number;
  chapterCount: number;
  lastReadChapter?: {
    id: number;
    title: string;
    chapter_number: number;
  };
  currentChapter?: {
    id: number;
    title: string;
    chapter_number: number;
  };
  // Preserve raw author details when the API includes them
  authorId?: number;
  authorAvatar?: string;
}

export interface ReadingListDetail extends ReadingList {
  books: BookshelfItem[];
}

const transformBookshelfItem = (book: any): BookshelfItem => {
  const author =
    typeof book?.author === 'object'
      ? book.author?.username || book.author?.name
      : book?.author;

  return {
    id: book?.id ?? book?.bookId ?? 0,
    bookId: book?.bookId ?? book?.id ?? 0,
    bookTitle: book?.bookTitle ?? book?.title ?? 'Untitled',
    bookCover: book?.bookCover ?? book?.cover ?? '',
    author: author || book?.author_name || book?.authorUsername || 'Unknown Author',
    lastReadAt: book?.lastReadAt ?? book?.addedAt ?? book?.updatedAt ?? new Date().toISOString(),
    progress: book?.progress ?? book?.readProgress ?? 0,
    addedAt: book?.addedAt ?? book?.createdAt ?? new Date().toISOString(),
    status: book?.status ?? 0,
    wordCount: book?.wordCount ?? book?.word_count ?? 0,
    chapterCount: book?.chapterCount ?? book?.chapter_count ?? 0,
    lastReadChapter: book?.lastReadChapter ?? book?.last_read_chapter,
    currentChapter: book?.currentChapter ?? book?.current_chapter,
    authorId:
      typeof book?.author === 'object'
        ? book.author?.id
        : book?.author_id ?? book?.authorId,
    authorAvatar:
      typeof book?.author === 'object'
        ? book.author?.avatar
        : book?.author_avatar ?? book?.authorAvatar,
  };
};

class ReadingListService {
  /**
   * Get user's reading lists
   */
  async getUserReadingLists(): Promise<ReadingList[]> {
    try {
      const response = await apiService.get<{
        success: boolean;
        data: { lists: ReadingList[] };
      }>('/reading-lists');
      return response.data.lists || [];
    } catch (error) {
      console.error('Failed to get reading lists:', error);
      return [];
    }
  }

  /**
   * Get user's starred/bookshelf books
   */
  async getStarredBooks(params?: { page?: number; limit?: number }): Promise<{
    books: BookshelfItem[];
    pagination: any;
  }> {
    try {
      const response = await apiService.get<{
        success: boolean;
        data: {
          books: BookshelfItem[];
          pagination: any;
        };
      }>('/reading-lists/starred-books', { params });
      const rawBooks = response.data.books || [];
      const normalizedBooks = rawBooks.map(transformBookshelfItem);

      return {
        books: normalizedBooks,
        pagination: response.data.pagination || { total: 0, page: 1, limit: 20, pages: 0 }
      };
    } catch (error) {
      console.error('Failed to get starred books:', error);
      return {
        books: [],
        pagination: { total: 0, page: 1, limit: 20, pages: 0 }
      };
    }
  }

  /**
   * Get reading list detail with books
   */
  async getReadingListDetail(listId: number, params?: { page?: number; limit?: number }): Promise<{
    list: ReadingListDetail | null;
    books: BookshelfItem[];
    pagination: any;
  }> {
    try {
      const response = await apiService.get<{
        success: boolean;
        data: {
          list: ReadingListDetail;
          books: BookshelfItem[];
          pagination: any;
        };
      }>(`/reading-lists/${listId}`, { params });
      const rawBooks = response.data.books || [];
      const normalizedBooks = rawBooks.map(transformBookshelfItem);

      return {
        list: response.data.list || null,
        books: normalizedBooks,
        pagination: response.data.pagination || { total: 0, page: 1, limit: 20, pages: 0 }
      };
    } catch (error) {
      console.error('Failed to get reading list detail:', error);
      return {
        list: null,
        books: [],
        pagination: { total: 0, page: 1, limit: 20, pages: 0 }
      };
    }
  }

  /**
   * Create a new reading list
   */
  async createReadingList(name: string, description?: string): Promise<ReadingList | null> {
    try {
      const response = await apiService.post<{
        success: boolean;
        data: { list: ReadingList };
      }>('/reading-lists', { name, description });
      return response.data.list || null;
    } catch (error) {
      console.error('Failed to create reading list:', error);
      throw error;
    }
  }

  /**
   * Delete a reading list
   */
  async deleteReadingList(listId: number): Promise<boolean> {
    try {
      await apiService.delete(`/reading-lists/${listId}`);
      return true;
    } catch (error) {
      console.error('Failed to delete reading list:', error);
      return false;
    }
  }

  /**
   * Add book to reading list
   */
  async addBookToList(listId: number, bookId: number): Promise<boolean> {
    try {
      await apiService.post(`/reading-lists/${listId}/books`, { bookId });
      return true;
    } catch (error) {
      console.error('Failed to add book to list:', error);
      throw error;
    }
  }

  /**
   * Remove book from reading list
   */
  async removeBookFromList(listId: number, bookId: number): Promise<boolean> {
    try {
      await apiService.delete(`/reading-lists/${listId}/books/${bookId}`);
      return true;
    } catch (error) {
      console.error('Failed to remove book from list:', error);
      return false;
    }
  }
}

export default new ReadingListService();
