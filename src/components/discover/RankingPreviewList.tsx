import React from 'react';
import { View, Text, Image, StyleSheet, TouchableOpacity } from 'react-native';
import { RankingItem } from '../../services/ranking.service';

interface RankingPreviewListProps {
  data: RankingItem[];
  metricLabel?: string;
  onItemPress?: (item: RankingItem) => void;
  formatScore?: (score: number, item: RankingItem) => string;
}

const RankingPreviewList: React.FC<RankingPreviewListProps> = ({
  data,
  metricLabel,
  onItemPress,
  formatScore,
}) => {
  if (!data || data.length === 0) {
    return null;
  }

  const handlePress = (item: RankingItem) => {
    if (onItemPress) {
      onItemPress(item);
    }
  };

  return (
    <View style={styles.container}>
      {data.map((item) => (
        <TouchableOpacity
          key={`${item.metric}-${item.book.id}`}
          style={styles.row}
          onPress={() => handlePress(item)}
          activeOpacity={0.8}
        >
          <View style={styles.rankCircle}>
            <Text style={styles.rankText}>{item.rank}</Text>
          </View>
          <View style={styles.coverWrapper}>
            {item.book.cover_image ? (
              <Image source={{ uri: item.book.cover_image }} style={styles.cover} resizeMode="cover" />
            ) : (
              <View style={styles.coverPlaceholder}>
                <Text style={styles.placeholderEmoji}>📖</Text>
              </View>
            )}
          </View>
          <View style={styles.info}>
            <Text style={styles.title} numberOfLines={2}>
              {item.book.title}
            </Text>
            <Text style={styles.author} numberOfLines={1}>
              {item.book.author || 'Unknown Author'}
            </Text>
            <Text style={styles.meta} numberOfLines={1}>
              {metricLabel ? `${metricLabel}: ` : ''}
              {formatScore ? formatScore(item.score, item) : item.score.toLocaleString()}
            </Text>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#fff',
    borderRadius: 16,
    marginHorizontal: 20,
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#e5e7eb',
  },
  rankCircle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#eef2ff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  rankText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#4338ca',
  },
  coverWrapper: {
    width: 52,
    height: 72,
    borderRadius: 10,
    overflow: 'hidden',
    backgroundColor: '#e5e7eb',
    marginRight: 12,
  },
  cover: {
    width: '100%',
    height: '100%',
  },
  coverPlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderEmoji: {
    fontSize: 20,
  },
  info: {
    flex: 1,
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
  meta: {
    marginTop: 6,
    fontSize: 12,
    fontWeight: '500',
    color: '#4f46e5',
  },
});

export default RankingPreviewList;
