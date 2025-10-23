import React, { useCallback, useEffect, useLayoutEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
  TouchableOpacity,
  Pressable,
} from 'react-native';
import { RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import chapterService, { ChapterDetail, ChapterSummary } from '../services/chapter.service';
import { RootStackParamList } from '../navigation/RootNavigator';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type ReaderScreenRouteProp = RouteProp<RootStackParamList, 'Reader'>;
type ReaderScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'Reader'>;

const MAX_CONTENT_LENGTH = 8000;

const extractContentText = (input: unknown, depth = 0, seen = new WeakSet<object>()): string => {
  if (input === null || input === undefined) return '';
  if (typeof input === 'string') return input;
  if (typeof input === 'number' || typeof input === 'boolean') return String(input);
  if (Array.isArray(input)) {
    return input
      .map((item) => extractContentText(item, depth + 1, seen))
      .filter(Boolean)
      .join('\n');
  }

  if (typeof input === 'object') {
    if (depth > 4) return '';
    const obj = input as Record<string, unknown>;
    if (seen.has(obj)) return '';
    seen.add(obj);

    if (typeof obj.message === 'string') return obj.message;
    if (typeof obj.text === 'string') return obj.text;

    if (Array.isArray(obj.blocks)) {
      return obj.blocks
        .map((block) => {
          if (block && typeof block === 'object' && 'text' in block) {
            return String((block as { text?: string }).text ?? '');
          }
          return extractContentText(block, depth + 1, seen);
        })
        .filter(Boolean)
        .join('\n');
    }

    if (Array.isArray((obj as { ops?: unknown[] }).ops)) {
      return ((obj as { ops: Array<{ insert?: unknown }> }).ops)
        .map((op) => {
          const insert = op.insert;
          if (typeof insert === 'string') return insert;
          if (insert && typeof insert === 'object' && 'text' in insert) {
            return String((insert as { text?: string }).text ?? '');
          }
          return extractContentText(insert, depth + 1, seen);
        })
        .filter(Boolean)
        .join('');
    }

    if (obj.content) {
      return extractContentText(obj.content, depth + 1, seen);
    }

    const nested = Object.values(obj)
      .map((value) => extractContentText(value, depth + 1, seen))
      .filter(Boolean)
      .join('\n');

    return nested || '';
  }

  return '';
};

const ReaderScreen: React.FC = () => {
  const navigation = useNavigation<ReaderScreenNavigationProp>();
  const route = useRoute<ReaderScreenRouteProp>();
  const { bookId, chapterId } = route.params;
  const insets = useSafeAreaInsets();

  const [chapters, setChapters] = useState<ChapterSummary[]>([]);
  const [currentChapter, setCurrentChapter] = useState<ChapterDetail | null>(null);
  const [currentIndex, setCurrentIndex] = useState<number>(0);
  const [loadingChapters, setLoadingChapters] = useState(true);
  const [loadingContent, setLoadingContent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [controlsVisible, setControlsVisible] = useState(true);
  const [fontSize, setFontSize] = useState(18);

  const loadChapters = useCallback(async () => {
    try {
      setLoadingChapters(true);
      setError(null);
      const fetched = await chapterService.getChaptersByBook(bookId);
      setChapters(fetched);

      if (fetched.length === 0) {
        setError('No chapters available yet.');
        return;
      }

      const initialIndex = chapterId
        ? Math.max(fetched.findIndex((chapter) => chapter.id === chapterId), 0)
        : 0;
      setCurrentIndex(initialIndex);
    } catch (err) {
      console.error('Failed to load chapters', err);
      setError('Unable to load chapters.');
    } finally {
      setLoadingChapters(false);
    }
  }, [bookId, chapterId]);

  const loadChapterContent = useCallback(async (index: number) => {
    if (!chapters[index]) return;
    const chapter = chapters[index];
    try {
      setLoadingContent(true);
      const detail = await chapterService.getChapterById(chapter.id);
      setCurrentChapter(detail);
      setCurrentIndex(index);
    } catch (err) {
      console.error('Failed to load chapter', err);
      setError('Unable to load chapter content.');
    } finally {
      setLoadingContent(false);
    }
  }, [chapters]);

  useEffect(() => {
    loadChapters();
  }, [loadChapters]);

  useEffect(() => {
    if (!loadingChapters && chapters.length > 0) {
      loadChapterContent(currentIndex);
    }
  }, [loadingChapters, chapters, currentIndex, loadChapterContent]);

  const hasPrevious = currentIndex > 0;
  const hasNext = currentIndex < chapters.length - 1;

  const handleNext = useCallback(() => {
    if (currentIndex < chapters.length - 1) {
      loadChapterContent(currentIndex + 1);
    }
  }, [chapters.length, currentIndex, loadChapterContent]);

  const handlePrevious = useCallback(() => {
    if (currentIndex > 0) {
      loadChapterContent(currentIndex - 1);
    }
  }, [currentIndex, loadChapterContent]);

  const handleToggleControls = () => {
    setControlsVisible((visible) => !visible);
  };

  const increaseFont = () => setFontSize((size) => Math.min(size + 2, 28));
  const decreaseFont = () => setFontSize((size) => Math.max(size - 2, 14));

  const bookTitle = useMemo(() => {
    if (!currentChapter) return 'Reader';
    if (currentChapter.book?.title) return currentChapter.book.title;
    if (currentChapter.title) return currentChapter.title;
    return 'Reader';
  }, [currentChapter]);

  const chapterNumberLabel = useMemo(() => {
    if (!currentChapter?.chapter_number) return null;
    return `Chapter ${currentChapter.chapter_number}`;
  }, [currentChapter]);

  const chapterHeading = useMemo(() => {
    if (!currentChapter) return 'Untitled Chapter';
    return currentChapter.title || 'Untitled Chapter';
  }, [currentChapter]);

  useLayoutEffect(() => {
    navigation.setOptions({ title: bookTitle });
  }, [navigation, bookTitle]);

  const displayContent = useMemo(() => {
    if (!currentChapter) return '';
    const { content } = currentChapter;

    const extracted = extractContentText(content).trim();

    if (!extracted) {
      return currentChapter.hasFullAccess ? 'Content unavailable.' : 'Content locked.';
    }

    return extracted.length > MAX_CONTENT_LENGTH
      ? `${extracted.slice(0, MAX_CONTENT_LENGTH)}…`
      : extracted;
  }, [currentChapter]);

  const purchaseNotice = useMemo(() => {
    if (!currentChapter || currentChapter.hasFullAccess || !currentChapter.purchaseInfo) return null;
    const { purchaseInfo } = currentChapter;
    const chapterPrice = purchaseInfo.chapterPrice ? `${purchaseInfo.chapterPrice} ${purchaseInfo.currency}` : null;
    const bookPrice = purchaseInfo.bookPrice ? `${purchaseInfo.bookPrice} ${purchaseInfo.currency}` : null;
    return {
      chapter: chapterPrice,
      book: bookPrice,
    };
  }, [currentChapter]);

  const computedLineHeight = useMemo(() => Math.round(fontSize * 1.6), [fontSize]);
  const progressPercent = useMemo(() => {
    if (!chapters.length) return 0;
    return Math.min(100, ((currentIndex + 1) / chapters.length) * 100);
  }, [chapters.length, currentIndex]);

  const topPadding = insets.top + 24;
  const bottomPadding = insets.bottom + (controlsVisible ? 160 : 80);

  const swipeGesture = useMemo(() => {
    return Gesture.Pan()
      .runOnJS(true)
      .activeOffsetX([-40, 40])
      .failOffsetY([-60, 60])
      .onEnd(({ translationX, velocityX }) => {
        const swipeDistance = Math.abs(translationX);
        const swipeVelocity = Math.abs(velocityX);
        const didSwipe = swipeDistance > 60 || swipeVelocity > 800;

        if (!didSwipe) {
          return;
        }

        if (translationX < 0 && hasNext) {
          handleNext();
        } else if (translationX > 0 && hasPrevious) {
          handlePrevious();
        }
      });
  }, [handleNext, handlePrevious, hasNext, hasPrevious]);

  if (loadingChapters) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#4f46e5" />
      </View>
    );
  }

  if (error || !currentChapter) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.errorText}>{error ?? 'Chapter unavailable.'}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={loadChapters}>
          <Text style={styles.retryText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <GestureDetector gesture={swipeGesture}>
        <ScrollView
          contentContainerStyle={[
            styles.contentContainer,
            { paddingTop: topPadding, paddingBottom: bottomPadding },
          ]}
        >
          <Pressable onPress={handleToggleControls}>
            {loadingContent ? (
              <ActivityIndicator size="small" color="#4f46e5" />
            ) : (
              <View>
                <View style={styles.titleBlock}>
                  {currentChapter.book?.title ? (
                    <Text style={styles.bookTitleText}>{currentChapter.book.title}</Text>
                  ) : null}
                  {chapterNumberLabel ? (
                    <Text style={styles.chapterNumber}>{chapterNumberLabel}</Text>
                  ) : null}
                  <Text style={styles.chapterHeading}>{chapterHeading}</Text>
                </View>
                <Text
                  style={[
                    styles.chapterContent,
                    { fontSize, lineHeight: computedLineHeight },
                  ]}
                >
                  {displayContent}
                </Text>
                {purchaseNotice && (
                  <View style={styles.purchaseNotice}>
                    <Text style={styles.purchaseTitle}>Unlock full chapter</Text>
                    {purchaseNotice.chapter && (
                      <Text style={styles.purchaseOption}>• Chapter: {purchaseNotice.chapter}</Text>
                    )}
                    {purchaseNotice.book && (
                      <Text style={styles.purchaseOption}>• Entire book: {purchaseNotice.book}</Text>
                    )}
                  </View>
                )}
              </View>
            )}
          </Pressable>
        </ScrollView>
      </GestureDetector>

      {controlsVisible && (
        <View style={[styles.bottomOverlay, { paddingBottom: insets.bottom + 20 }]}>
          <View style={styles.progressGroup}>
            <Text style={styles.progressText}>
              {Math.min(currentIndex + 1, chapters.length)} / {chapters.length}
            </Text>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: `${progressPercent}%` }]} />
            </View>
          </View>

          <View style={styles.controlRow}>
            <TouchableOpacity
              style={[styles.roundButton, !hasPrevious && styles.roundButtonDisabled]}
              onPress={handlePrevious}
              disabled={!hasPrevious || loadingContent}
            >
              <Ionicons name="chevron-back" size={20} color={hasPrevious ? '#0f172a' : '#94a3b8'} />
            </TouchableOpacity>

            <View style={styles.fontControls}>
              <TouchableOpacity style={styles.fontButton} onPress={decreaseFont}>
                <Text style={styles.fontButtonText}>A-</Text>
              </TouchableOpacity>
              <Text style={styles.fontSizeLabel}>{fontSize}px</Text>
              <TouchableOpacity style={styles.fontButton} onPress={increaseFont}>
                <Text style={styles.fontButtonText}>A+</Text>
              </TouchableOpacity>
            </View>

            <TouchableOpacity
              style={[styles.roundButton, !hasNext && styles.roundButtonDisabled]}
              onPress={handleNext}
              disabled={!hasNext || loadingContent}
            >
              <Ionicons name="chevron-forward" size={20} color={hasNext ? '#0f172a' : '#94a3b8'} />
            </TouchableOpacity>
          </View>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8fafc',
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
  contentContainer: {
    paddingHorizontal: 24,
  },
  titleBlock: {
    marginBottom: 24,
  },
  bookTitleText: {
    fontSize: 12,
    color: '#64748b',
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  chapterNumber: {
    fontSize: 14,
    color: '#6366f1',
    fontWeight: '600',
    marginBottom: 6,
  },
  chapterHeading: {
    fontSize: 24,
    fontWeight: '700',
    color: '#0f172a',
    marginBottom: 18,
  },
  chapterContent: {
    color: '#0f172a',
    textAlign: 'left',
  },
  purchaseNotice: {
    marginTop: 16,
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#eef2ff',
  },
  purchaseTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#312e81',
    marginBottom: 4,
  },
  purchaseOption: {
    fontSize: 13,
    color: '#4338ca',
  },
  bottomOverlay: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 0,
    backgroundColor: 'rgba(248, 250, 252, 0.96)',
    borderRadius: 18,
    paddingHorizontal: 18,
    paddingTop: 18,
    shadowColor: '#0f172a',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.12,
    shadowRadius: 24,
    elevation: 6,
  },
  progressGroup: {
    marginBottom: 16,
  },
  progressText: {
    fontSize: 12,
    color: '#64748b',
    fontWeight: '600',
    marginBottom: 6,
  },
  progressBar: {
    height: 4,
    borderRadius: 999,
    backgroundColor: '#e2e8f0',
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#6366f1',
  },
  controlRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  roundButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#e2e8f0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  roundButtonDisabled: {
    backgroundColor: '#e2e8f0',
    opacity: 0.5,
  },
  fontControls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#eef2ff',
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  fontButton: {
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  fontButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#4338ca',
  },
  fontSizeLabel: {
    fontSize: 13,
    color: '#6366f1',
    fontWeight: '600',
  },
});

export default ReaderScreen;
