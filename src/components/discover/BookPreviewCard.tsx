import React from 'react';
import { View, Text, Image, StyleSheet, TouchableOpacity } from 'react-native';

export interface PreviewBook {
  id: string;
  title: string;
  author?: string | null;
  coverUrl?: string | null;
  description?: string | null;
  badge?: string;
  scoreLabel?: string;
}

interface BookPreviewCardProps {
  book: PreviewBook;
  onPress?: (book: PreviewBook) => void;
}

const BookPreviewCard: React.FC<BookPreviewCardProps> = ({ book, onPress }) => {
  const handlePress = () => {
    if (onPress) {
      onPress(book);
    }
  };

  return (
    <TouchableOpacity style={styles.container} activeOpacity={0.82} onPress={handlePress}>
      <View style={styles.coverWrapper}>
        {book.coverUrl ? (
          <Image source={{ uri: book.coverUrl }} style={styles.cover} resizeMode="cover" />
        ) : (
          <View style={styles.placeholderCover}>
            <Text style={styles.placeholderEmoji}>📘</Text>
          </View>
        )}
        {book.badge ? (
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{book.badge}</Text>
          </View>
        ) : null}
      </View>
      <View style={styles.metaContainer}>
        <Text style={styles.title} numberOfLines={2}>
          {book.title}
        </Text>
        {book.author ? (
          <Text style={styles.author} numberOfLines={1}>
            {book.author}
          </Text>
        ) : null}
        {book.scoreLabel ? (
          <Text style={styles.scoreLabel} numberOfLines={1}>
            {book.scoreLabel}
          </Text>
        ) : null}
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    width: 140,
    marginRight: 16,
  },
  coverWrapper: {
    width: '100%',
    aspectRatio: 3 / 4,
    borderRadius: 16,
    overflow: 'hidden',
    backgroundColor: '#e0e7ff',
  },
  cover: {
    width: '100%',
    height: '100%',
  },
  placeholderCover: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderEmoji: {
    fontSize: 32,
  },
  badge: {
    position: 'absolute',
    top: 8,
    left: 8,
    backgroundColor: 'rgba(79,70,229,0.9)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
  },
  badgeText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#fff',
    letterSpacing: 0.5,
  },
  metaContainer: {
    marginTop: 10,
  },
  title: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111827',
  },
  author: {
    marginTop: 4,
    fontSize: 12,
    color: '#6b7280',
  },
  scoreLabel: {
    marginTop: 4,
    fontSize: 11,
    color: '#4f46e5',
    fontWeight: '500',
  },
});

export default BookPreviewCard;
