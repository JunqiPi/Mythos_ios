import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

interface SectionHeaderProps {
  title: string;
  subtitle?: string;
  actionLabel?: string;
  onPressAction?: () => void;
}

const SectionHeader: React.FC<SectionHeaderProps> = ({
  title,
  subtitle,
  actionLabel,
  onPressAction,
}) => {
  return (
    <View style={styles.container}>
      <View style={styles.textContainer}>
        <Text style={styles.title}>{title}</Text>
        {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
      </View>
      {actionLabel && onPressAction ? (
        <TouchableOpacity onPress={onPressAction} style={styles.actionButton} activeOpacity={0.8}>
          <Text style={styles.actionLabel}>{actionLabel}</Text>
        </TouchableOpacity>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    paddingHorizontal: 20,
    marginBottom: 12,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
  },
  subtitle: {
    marginTop: 4,
    fontSize: 13,
    color: '#6b7280',
  },
  actionButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: '#eef2ff',
  },
  actionLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#4f46e5',
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
});

export default SectionHeader;
