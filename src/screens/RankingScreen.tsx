import React, { useEffect, useState, useCallback, useMemo } from 'react';
import {
  View,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
  Text,
  RefreshControl,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { NavigationProp, useNavigation } from '@react-navigation/native';
import rankingService, { RankingItem } from '../services/ranking.service';
import SectionHeader from '../components/discover/SectionHeader';
import RankingPreviewList from '../components/discover/RankingPreviewList';
import { RootStackParamList } from '../navigation/RootNavigator';

const METRICS = [
  {
    key: 'reading_index',
    title: 'Reading Index',
    description: 'Combines velocity, engagement, retention, social proof, and freshness.',
  },
  {
    key: 'gems',
    title: 'Gem Index',
    description: 'Total gems gifted across the lifetime of the title.',
  },
  {
    key: 'stars',
    title: 'Star Rank',
    description: 'Readers’ bookshelf saves and favorites.',
  },
  {
    key: 'popularity',
    title: 'Popularity Rank',
    description: 'Weighted mix of likes and overall activity.',
  },
  {
    key: 'hidden_gems',
    title: 'Hidden Gems',
    description: 'Newer titles with strong growth signals.',
  },
  {
    key: 'completion',
    title: 'Completed',
    description: 'Finished stories with high endgame energy.',
  },
] as const;

const METRIC_ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  reading_index: 'speedometer-outline',
  gems: 'diamond-outline',
  stars: 'star-outline',
  popularity: 'flame-outline',
  hidden_gems: 'sparkles-outline',
  completion: 'checkmark-done-outline',
};

const RankingScreen: React.FC = () => {
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [metricRankings, setMetricRankings] = useState<Record<string, RankingItem[]>>({});
  const [selectedMetric, setSelectedMetric] = useState<typeof METRICS[number]['key']>('reading_index');
  const [metricErrors, setMetricErrors] = useState<Record<string, string | null>>({});

  const loadData = useCallback(async (isRefresh = false) => {
    try {
      if (isRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }
      setError(null);

      const results = await Promise.allSettled(
        METRICS.map(({ key }) =>
          rankingService.getBookRankings({
            type: 'all_time',
            metric: key as 'gems' | 'reading_index' | 'stars' | 'popularity' | 'hidden_gems' | 'completion',
            page_size: 10,
          })
        )
      );

      const nextRankings: Record<string, RankingItem[]> = {};
      const nextErrors: Record<string, string | null> = {};

      results.forEach((result, index) => {
        const metricKey = METRICS[index].key;
        if (result.status === 'fulfilled') {
          const list = result.value.data || [];
          nextRankings[metricKey] = list.map((item, idx) => ({
            ...item,
            rank: idx + 1,
            score:
              typeof item.score === 'number'
                ? item.score
                : Number(item.score) || 0,
          }));
          nextErrors[metricKey] = null;
        } else {
          console.warn(
            `[RankingScreen] Failed to load metric "${metricKey}":`,
            result.reason?.message || result.reason
          );
          nextRankings[metricKey] = [];
          nextErrors[metricKey] = 'Temporarily unavailable.';
        }
      });

      setMetricRankings(nextRankings);
      setMetricErrors(nextErrors);
    } catch (err) {
      console.error('Failed to load ranking data', err);
      setError('Unable to load ranking data. Pull to refresh.');
      setMetricErrors({});
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleRefresh = useCallback(() => {
    loadData(true);
  }, [loadData]);

  const handleRankingPress = useCallback((item: RankingItem) => {
    const targetId = Number(item.book.id);
    if (!Number.isNaN(targetId)) {
      navigation.navigate('BookDetail', { bookId: targetId });
    }
  }, [navigation]);

  const currentMetric = useMemo(
    () => METRICS.find((metric) => metric.key === selectedMetric) ?? METRICS[0],
    [selectedMetric]
  );
  const currentRankings = metricRankings[selectedMetric] || [];
  const highlightItem = currentRankings[0] || null;
  const metricError = metricErrors[selectedMetric];

  const formatScoreValue = useCallback((score: number, metricKey: string) => {
    const value = Number(score) || 0;
    const fractionalMetrics = ['reading_index', 'hidden_gems', 'completion'];
    const options = fractionalMetrics.includes(metricKey)
      ? { maximumFractionDigits: 2, minimumFractionDigits: 0 }
      : { maximumFractionDigits: 0 };
    return value.toLocaleString(undefined, options);
  }, []);

  const formattedHighlightScore = highlightItem
    ? formatScoreValue(highlightItem.score, currentMetric.key)
    : null;

  if (loading && !refreshing) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#4f46e5" />
        <Text style={styles.loadingText}>Gathering rankings…</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={['#4f46e5']}
            tintColor="#4f46e5"
          />
        }
      >
        {error ? (
          <View style={styles.errorBanner}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        <View style={styles.heroCard}>
          <View style={styles.heroContent}>
            <Text style={styles.heroTitle}>Rankings Hub</Text>
            <Text style={styles.heroSubtitle}>
              Drill into Mythos metrics like an editor. Tap a chip below to change the lens.
            </Text>
          </View>
          <Ionicons name="trophy-outline" size={32} color="#ffffff" style={styles.heroIcon} />
        </View>

        <SectionHeader
          title="All-Time Rankings"
          subtitle="Tap metrics to view their top stories"
        />

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.metricChips}
        >
          {METRICS.map(({ key, title }) => {
            const active = key === selectedMetric;
            return (
              <TouchableOpacity
                key={key}
                onPress={() => setSelectedMetric(key)}
                style={[styles.metricChip, active && styles.metricChipActive]}
                activeOpacity={0.85}
              >
                <Ionicons
                  name={METRIC_ICONS[key] || 'analytics-outline'}
                  size={16}
                  color={active ? '#fff' : '#4f46e5'}
                  style={styles.metricChipIcon}
                />
                <Text style={[styles.metricChipText, active && styles.metricChipTextActive]}>
                  {title}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>

        <View style={styles.metricBlock}>
          <Text style={styles.metricTitle}>{currentMetric.title}</Text>
          <Text style={styles.metricDescription}>{currentMetric.description}</Text>

          {highlightItem ? (
            <TouchableOpacity
              style={styles.highlightCard}
              activeOpacity={0.85}
              onPress={() => handleRankingPress(highlightItem)}
            >
              <View style={styles.highlightBadge}>
                <Text style={styles.highlightRank}>#{highlightItem.rank}</Text>
              </View>
              <View style={styles.highlightInfo}>
                <Text style={styles.highlightTitle} numberOfLines={1}>
                  {highlightItem.book.title}
                </Text>
                <Text style={styles.highlightMeta} numberOfLines={1}>
                  {highlightItem.book.author || 'Unknown Author'} • {currentMetric.title}
                </Text>
              </View>
              <Text style={styles.highlightScore}>{formattedHighlightScore}</Text>
            </TouchableOpacity>
          ) : null}

          <RankingPreviewList
            data={currentRankings}
            metricLabel={currentMetric.title}
            onItemPress={handleRankingPress}
            formatScore={(score) => formatScoreValue(score, currentMetric.key)}
          />

          {metricError ? (
            <Text style={styles.emptyText}>{metricError}</Text>
          ) : currentRankings.length === 0 ? (
            <Text style={styles.emptyText}>No data yet for {currentMetric.title}.</Text>
          ) : null}
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5fb',
  },
  scrollContent: {
    paddingTop: 24,
    paddingBottom: 48,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5fb',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 15,
    color: '#6b7280',
  },
  errorBanner: {
    marginHorizontal: 20,
    marginBottom: 16,
    padding: 12,
    borderRadius: 14,
    backgroundColor: '#fee2e2',
  },
  errorText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#b91c1c',
  },
  heroCard: {
    marginHorizontal: 20,
    marginBottom: 24,
    backgroundColor: '#4338ca',
    borderRadius: 20,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
  },
  heroContent: {
    flex: 1,
  },
  heroTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#fff',
    marginBottom: 6,
  },
  heroSubtitle: {
    fontSize: 13,
    lineHeight: 18,
    color: 'rgba(255,255,255,0.85)',
  },
  heroIcon: {
    marginLeft: 16,
  },
  metricChips: {
    paddingHorizontal: 20,
    paddingVertical: 4,
    flexDirection: 'row',
  },
  metricChip: {
    borderRadius: 999,
    backgroundColor: '#ede9fe',
    paddingHorizontal: 14,
    paddingVertical: 8,
    marginRight: 8,
    flexDirection: 'row',
    alignItems: 'center',
  },
  metricChipActive: {
    backgroundColor: '#4f46e5',
  },
  metricChipIcon: {
    marginRight: 6,
  },
  metricChipText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#6b7280',
  },
  metricChipTextActive: {
    color: '#fff',
  },
  metricBlock: {
    marginBottom: 24,
  },
  metricTitle: {
    marginLeft: 20,
    marginBottom: 8,
    fontSize: 14,
    fontWeight: '600',
    color: '#1f2937',
  },
  metricDescription: {
    marginLeft: 20,
    marginRight: 20,
    marginBottom: 8,
    fontSize: 12,
    color: '#6b7280',
  },
  highlightCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#eef2ff',
    marginHorizontal: 20,
    marginBottom: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 14,
  },
  highlightBadge: {
    backgroundColor: '#4f46e5',
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 6,
    marginRight: 12,
  },
  highlightRank: {
    fontSize: 18,
    fontWeight: '800',
    color: '#fff',
  },
  highlightInfo: {
    flex: 1,
  },
  highlightTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#1f2937',
  },
  highlightMeta: {
    marginTop: 2,
    fontSize: 12,
    color: '#6b7280',
  },
  highlightScore: {
    fontSize: 14,
    fontWeight: '700',
    color: '#4f46e5',
    marginLeft: 12,
  },
  emptyText: {
    marginHorizontal: 20,
    marginBottom: 16,
    fontSize: 12,
    color: '#9ca3af',
    textAlign: 'left',
  },
});

export default RankingScreen;
