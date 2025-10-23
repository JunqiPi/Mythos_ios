import React from 'react';
import { View, Text, ImageBackground, StyleSheet, TouchableOpacity } from 'react-native';
import { PreviewBook } from './BookPreviewCard';

interface DiscoverHeroProps {
  book: PreviewBook | null;
  onPress?: (book: PreviewBook) => void;
  title?: string;
  subtitle?: string;
}

const DiscoverHero: React.FC<DiscoverHeroProps> = ({ book, onPress, title, subtitle }) => {
  if (!book) {
    return null;
  }

  const handlePress = () => {
    if (book && onPress) {
      onPress(book);
    }
  };

  return (
    <TouchableOpacity activeOpacity={0.88} onPress={handlePress} style={styles.container}>
      <ImageBackground
        source={book.coverUrl ? { uri: book.coverUrl } : undefined}
        style={styles.background}
        imageStyle={styles.backgroundImage}
        resizeMode={book.coverUrl ? 'cover' : 'contain'}
      >
        <View style={styles.overlay} />
        <View style={styles.content}>
          <Text style={styles.kicker}>{title || 'Center of the World'}</Text>
          <Text style={styles.heroTitle} numberOfLines={2}>
            {book.title}
          </Text>
          {subtitle ? (
            <Text style={styles.heroSubtitle} numberOfLines={2}>
              {subtitle}
            </Text>
          ) : null}
          <View style={styles.ctaRow}>
            <View style={styles.ctaBadge}>
              <Text style={styles.ctaText}>Read Now</Text>
            </View>
            {book.author ? <Text style={styles.author}>by {book.author}</Text> : null}
          </View>
        </View>
      </ImageBackground>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    marginHorizontal: 20,
    marginBottom: 28,
    borderRadius: 24,
    overflow: 'hidden',
    backgroundColor: '#1f2937',
  },
  background: {
    width: '100%',
    height: 220,
    justifyContent: 'flex-end',
  },
  backgroundImage: {
    opacity: 0.55,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(17, 24, 39, 0.65)',
  },
  content: {
    paddingHorizontal: 24,
    paddingVertical: 28,
  },
  kicker: {
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 1.2,
    color: '#c7d2fe',
    marginBottom: 8,
  },
  heroTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: '#fff',
    marginBottom: 10,
  },
  heroSubtitle: {
    fontSize: 14,
    color: '#e0e7ff',
    marginBottom: 16,
  },
  ctaRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  ctaBadge: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: '#4f46e5',
  },
  ctaText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#fff',
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  author: {
    fontSize: 13,
    color: '#c7d2fe',
    marginLeft: 12,
  },
});

export default DiscoverHero;
