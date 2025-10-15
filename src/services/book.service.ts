import apiService from './api.service';

export interface Book {
  id: string;
  title: string;
  description: string;
  cover_url: string | null;
  tags: string[];
  status: number;
  category: number;
  word_number: number;
  read_count: number;
  like_count: number;
  comment_count: number;
  created_at: string;
  updated_at: string;
  user: {
    id: string;
    username: string;
    avatar_url: string;
  };
}

export interface BooksResponse {
  success: boolean;
  message: string;
  data: Book[];
  pagination?: {
    currentPage: number;
    totalPages: number;
    totalBooks: number;
    limit: number;
  };
}

class BookService {
  async getBooks(page: number = 1, limit: number = 10): Promise<BooksResponse> {
    return await apiService.get<BooksResponse>(`/books?page=${page}&limit=${limit}`);
  }

  async getBookById(id: string): Promise<Book> {
    const response = await apiService.get<{ success: boolean; data: Book }>(`/books/${id}`);
    return response.data;
  }

  async searchBooks(query: string, page: number = 1, limit: number = 10): Promise<BooksResponse> {
    return await apiService.get<BooksResponse>(
      `/books/search?q=${encodeURIComponent(query)}&page=${page}&limit=${limit}`
    );
  }

  async getPopularBooks(): Promise<BooksResponse> {
    return await apiService.get<BooksResponse>('/books?sort=popular&limit=10');
  }

  async getRecentBooks(): Promise<BooksResponse> {
    return await apiService.get<BooksResponse>('/books?sort=recent&limit=10');
  }
}

export default new BookService();
