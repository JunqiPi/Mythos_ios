import apiService from './api.service';

export interface RankingBook {
  id: number;
  title: string;
  author: string;
  cover_image?: string | null;
  description?: string | null;
  category?: string | null;
  categoryName?: string | null;
  tags?: Array<number | string>;
  tagNames?: string[];
  word_count?: number;
  status?: number;
}

export interface RankingItem {
  rank: number;
  book: RankingBook;
  score: number;
  period?: string | null;
  metric: string;
}

export interface HotRankingsResponse {
  data: Record<string, RankingItem[]>;
  generated_at: string;
}

export interface BookRankingParams {
  type?: 'monthly' | 'yearly_rolling' | 'all_time';
  period?: string;
  metric?: 'gems' | 'reading_index' | 'stars' | 'popularity' | 'hidden_gems' | 'completion';
  category?: string;
  word_count_min?: number;
  word_count_max?: number;
  page?: number;
  page_size?: number;
}

export interface HotRankingParams {
  metrics?: string[];
  limit?: number;
}

export interface AuthorRankingParams {
  type?: 'followers' | 'books' | 'gems_received' | 'composite';
  period?: string;
  page?: number;
  page_size?: number;
}

export interface CharacterRankingParams {
  time_range?: 'month' | 'year' | 'all';
  period?: string;
  page?: number;
  page_size?: number;
}

export interface AuthorRankingItem {
  rank: number;
  user: {
    id: number;
    username: string;
    pen_name?: string;
    avatar_url?: string | null;
    bio?: string | null;
  };
  followers_count?: number;
  book_count?: number;
  total_gems?: number;
  gems_received?: number;
  composite_score?: number;
  metrics?: {
    total_views: number;
    followers_count: number;
    total_gems: number;
    active_book_count: number;
    total_book_count: number;
  };
  score_breakdown?: {
    views_contribution: number;
    followers_contribution: number;
    gems_contribution: number;
  };
}

export interface CharacterRankingItem {
  rank: number;
  character: {
    id: number;
    name: string;
    book_title: string;
    book_id: number;
  };
  like_count: number;
  gems_count: number;
}

class RankingService {
  async getBookRankings(params: BookRankingParams = {}) {
    const queryParams = {
      type: params.type || 'all_time',
      period: params.period,
      metric: params.metric || 'gems',
      category: params.category,
      word_count_min: params.word_count_min,
      word_count_max: params.word_count_max,
      page: params.page || 1,
      page_size: params.page_size || 10,
    };

    Object.keys(queryParams).forEach((key) => {
      if (queryParams[key as keyof typeof queryParams] === undefined) {
        delete queryParams[key as keyof typeof queryParams];
      }
    });

    try {
      const response = await apiService.get<{
        success: boolean;
        data: RankingItem[];
        pagination: {
          current_page: number;
          total_pages: number;
          total_items: number;
          per_page: number;
        };
        period_info: {
          type: string;
          period?: string;
          metric?: string;
          available_periods?: string[];
        };
      }>('/rankings/books', { params: queryParams });

      return {
        data: response.data || [],
        pagination: response.pagination,
        period_info: response.period_info,
      };
    } catch (error) {
      console.error('Failed to fetch book rankings', error);
      return {
        data: [] as RankingItem[],
        pagination: {
          current_page: params.page || 1,
          total_pages: 0,
          total_items: 0,
          per_page: params.page_size || 10,
        },
        period_info: {
          type: params.type || 'all_time',
          period: params.period,
          metric: params.metric || 'gems',
        },
      };
    }
  }

  async getHotRankings(params: HotRankingParams = {}): Promise<HotRankingsResponse> {
    const metrics = params.metrics?.join(',') || 'gems,reading_index,stars,popularity';
    const limit = params.limit || 6;

    try {
      const response = await apiService.get<{
        success: boolean;
        data: Record<string, RankingItem[]>;
        generated_at: string;
      }>('/rankings/hot', { params: { metrics, limit } });

      return {
        data: response.data || {},
        generated_at: response.generated_at,
      };
    } catch (error) {
      console.error('Failed to fetch hot rankings', error);
      return {
        data: {},
        generated_at: new Date().toISOString(),
      };
    }
  }

  async getAuthorRankings(params: AuthorRankingParams = {}) {
    const queryParams = {
      type: params.type || 'followers',
      period: params.period,
      page: params.page || 1,
      page_size: params.page_size || 10,
    };

    Object.keys(queryParams).forEach((key) => {
      if (queryParams[key as keyof typeof queryParams] === undefined) {
        delete queryParams[key as keyof typeof queryParams];
      }
    });

    try {
      const response = await apiService.get<{
        success: boolean;
        data: AuthorRankingItem[];
        pagination: {
          current_page: number;
          total_pages: number;
          total_items: number;
          per_page: number;
        };
        ranking_info: {
          type: string;
          period?: string;
        };
      }>('/rankings/authors', { params: queryParams });

      return {
        data: response.data || [],
        pagination: response.pagination,
        ranking_info: response.ranking_info,
      };
    } catch (error) {
      console.error('Failed to fetch author rankings', error);
      return {
        data: [] as AuthorRankingItem[],
        pagination: {
          current_page: params.page || 1,
          total_pages: 0,
          total_items: 0,
          per_page: params.page_size || 10,
        },
        ranking_info: {
          type: params.type || 'followers',
          period: params.period,
        },
      };
    }
  }

  async getCharacterRankings(params: CharacterRankingParams = {}) {
    const queryParams = {
      time_range: params.time_range || 'all',
      period: params.period,
      page: params.page || 1,
      page_size: params.page_size || 10,
    };

    Object.keys(queryParams).forEach((key) => {
      if (queryParams[key as keyof typeof queryParams] === undefined) {
        delete queryParams[key as keyof typeof queryParams];
      }
    });

    try {
      const response = await apiService.get<{
        success: boolean;
        data: CharacterRankingItem[];
        pagination: {
          current_page: number;
          total_pages: number;
          total_items: number;
          per_page: number;
        };
        ranking_info: {
          time_range: string;
          period?: string;
        };
      }>('/rankings/characters', { params: queryParams });

      return {
        data: response.data || [],
        pagination: response.pagination,
        ranking_info: response.ranking_info,
      };
    } catch (error) {
      console.error('Failed to fetch character rankings', error);
      return {
        data: [] as CharacterRankingItem[],
        pagination: {
          current_page: params.page || 1,
          total_pages: 0,
          total_items: 0,
          per_page: params.page_size || 10,
        },
        ranking_info: {
          time_range: params.time_range || 'all',
          period: params.period,
        },
      };
    }
  }
}

export default new RankingService();
