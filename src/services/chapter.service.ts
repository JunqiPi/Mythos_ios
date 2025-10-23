import apiService from './api.service';

export interface ChapterSummary {
  id: number;
  book_id: number;
  title: string;
  chapter_number: number | null;
  content?: string;
  preview_content?: string;
  is_locked?: boolean;
  status: number;
  nextChapter?: {
    id: number;
    chapter_number: number;
    title: string;
    status: number;
    is_locked: boolean;
  } | null;
  prevChapter?: {
    id: number;
    chapter_number: number;
    title: string;
    status: number;
    is_locked: boolean;
  } | null;
}

export interface ChapterPurchaseOption {
  type: 'chapter' | 'book';
  price: number;
  description: string;
}

export interface ChapterPurchaseInfo {
  chapterPrice: number;
  bookPrice: number;
  currency: string;
  chapterTitle: string;
  bookTitle: string;
  purchaseOptions: ChapterPurchaseOption[];
}

export interface ChapterBookInfo {
  id?: number;
  title?: string;
  cover_url?: string;
  user_id?: number;
}

export type ChapterDetail = Omit<ChapterSummary, 'content'> & {
  content: string | Record<string, unknown> | null;
  hasFullAccess: boolean;
  unlockReason?: string;
  purchaseInfo?: ChapterPurchaseInfo;
  book?: ChapterBookInfo;
};

class ChapterService {
  async getChaptersByBook(bookId: number): Promise<ChapterSummary[]> {
    const response = await apiService.get<{ success: boolean; data: ChapterSummary[] }>(
      `/chapters/book/${bookId}`,
      { params: { status: 1 } }
    );
    return response.data || [];
  }

  async getChapterById(chapterId: number): Promise<ChapterDetail> {
    const response = await apiService.get<{ success: boolean; data: ChapterDetail }>(
      `/chapters/${chapterId}`
    );
    return response.data;
  }
}

export default new ChapterService();
