import React from 'react';
import { View, FlatList, StyleSheet } from 'react-native';
import BookPreviewCard, { PreviewBook } from './BookPreviewCard';

interface HorizontalBookListProps {
  data: PreviewBook[];
  onPressItem?: (book: PreviewBook) => void;
  contentPaddingHorizontal?: number;
}

const HorizontalBookList: React.FC<HorizontalBookListProps> = ({
  data,
  onPressItem,
  contentPaddingHorizontal = 20,
}) => {
  if (!data || data.length === 0) {
    return null;
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={data}
        renderItem={({ item }) => <BookPreviewCard book={item} onPress={onPressItem} />}
        keyExtractor={(item) => item.id}
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingHorizontal: contentPaddingHorizontal },
        ]}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 24,
  },
  contentContainer: {
    paddingVertical: 4,
  },
});

export default HorizontalBookList;
