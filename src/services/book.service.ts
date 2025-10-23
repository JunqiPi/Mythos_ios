import apiService from './api.service';

export interface Book {
  id: string;
  title: string;
  description: string;
  cover_url: string | null;
  tags: string[];
  status: number;
  category: number | null;
  word_number: number;
  read_count: number;
  like_count: number;
  comment_count: number;
  created_at: string;
  updated_at: string;
  total_gem_count?: number;
  starred_count?: number;
  rating?: number;
  tagNames?: string[];
  categoryName?: string;
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
    currentPage?: number;
    current_page?: number;
    totalPages?: number;
    total_pages?: number;
    totalBooks?: number;
    total_items?: number;
    limit?: number;
    per_page?: number;
  };
}

export interface GetBooksParams {
  page?: number;
  limit?: number;
  sort_by?: string;
  sort_direction?: 'asc' | 'desc';
  category?: string;
  metric?: string;
  search?: string;
}

export interface FrontPageBooksResponse {
  editor_picks: Book[];
  hot_recommendations: Book[];
  config_source: 'system_config' | 'default';
  total_configured?: number;
}

class BookService {
  private buildQuery(params: Record<string, string | number | undefined | null>) {
    const query = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value === undefined || value === null || value === '') return;
      query.append(key, String(value));
    });
    const queryString = query.toString();
    return queryString ? `?${queryString}` : '';
  }

  async getBooks(params: GetBooksParams = {}): Promise<BooksResponse> {
    const {
      page = 1,
      limit = 10,
      sort_by,
      sort_direction,
      category,
      metric,
      search,
    } = params;

    const query = this.buildQuery({
      page,
      limit,
      sort_by,
      sort_direction,
      category,
      metric,
      search,
    });

    return await apiService.get<BooksResponse>(`/books${query}`);
  }

  async getBookById(id: string): Promise<Book> {
    const response = await apiService.get<{ success: boolean; data: Book }>(`/books/${id}`);
    return response.data;
  }

  async searchBooks(query: string, page: number = 1, limit: number = 10): Promise<BooksResponse> {
    return await apiService.get<BooksResponse>('/search', {
      params: {
        query,
        page,
        page_size: limit,
      },
    });
  }

  async getPopularBooks(): Promise<BooksResponse> {
    return await apiService.get<BooksResponse>('/books?sort=popular&limit=10');
  }

  async getRecentBooks(): Promise<BooksResponse> {
    return await apiService.get<BooksResponse>('/books?sort=recent&limit=10');
  }

  async getFrontPageBooks(): Promise<FrontPageBooksResponse> {
    const response = await apiService.get<{ success: boolean; data: FrontPageBooksResponse }>('/books/front-page');
    return response.data;
  }
}

export default new BookService();
