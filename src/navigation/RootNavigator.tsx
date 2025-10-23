import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import TabNavigator from './TabNavigator';
import BookDetailScreen from '../screens/BookDetailScreen';
import ReaderScreen from '../screens/ReaderScreen';

export type RootStackParamList = {
  Tabs: undefined;
  BookDetail: { bookId: number };
  Reader: { bookId: number; chapterId?: number };
};

const Stack = createNativeStackNavigator<RootStackParamList>();

const RootNavigator = () => (
  <Stack.Navigator
    screenOptions={{
      headerStyle: { backgroundColor: '#4f46e5' },
      headerTintColor: '#fff',
      headerTitleStyle: { fontWeight: '700' },
    }}
  >
    <Stack.Screen
      name="Tabs"
      component={TabNavigator}
      options={{ headerShown: false }}
    />
    <Stack.Screen
      name="BookDetail"
      component={BookDetailScreen}
      options={{ title: 'Book Details' }}
    />
    <Stack.Screen
      name="Reader"
      component={ReaderScreen}
      options={{ title: 'Reader' }}
    />
  </Stack.Navigator>
);

export default RootNavigator;
