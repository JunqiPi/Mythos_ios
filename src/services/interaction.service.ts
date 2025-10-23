import apiService from './api.service';

export interface BookInteractionState {
  book_id: number;
  liked: boolean;
  starred: boolean;
  following_author: boolean;
}

export interface ToggleLikeResponse {
  book_id: number;
  liked: boolean;
  like_count: number;
}

export interface ToggleStarResponse {
  book_id: number;
  starred: boolean;
  star_count: number;
}

class InteractionService {
  async getBookInteractions(bookId: number): Promise<BookInteractionState> {
    const response = await apiService.get<{ success: boolean; data: BookInteractionState }>(
      `/interactions/user/book/${bookId}`
    );
    return response.data;
  }

  async toggleBookLike(bookId: number): Promise<ToggleLikeResponse> {
    const response = await apiService.post<ToggleLikeResponse>(`/interactions/book/${bookId}/like`);
    return response;
  }

  async toggleBookStar(bookId: number): Promise<ToggleStarResponse> {
    const response = await apiService.post<ToggleStarResponse>(`/interactions/book/${bookId}/star`);
    return response;
  }
}

export default new InteractionService();
