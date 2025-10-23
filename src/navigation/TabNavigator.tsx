import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';

import DiscoverScreen from '../screens/DiscoverScreen';
import RankingScreen from '../screens/RankingScreen';
import LibraryScreen from '../screens/LibraryScreen';
import ProfileScreen from '../screens/ProfileScreen';

export type TabParamList = {
  Discover: undefined;
  Ranking: undefined;
  Library: undefined;
  Profile: undefined;
};

const Tab = createBottomTabNavigator<TabParamList>();

export default function TabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap;

          if (route.name === 'Discover') {
            iconName = focused ? 'book' : 'book-outline';
          } else if (route.name === 'Ranking') {
            iconName = focused ? 'trophy' : 'trophy-outline';
          } else if (route.name === 'Library') {
            iconName = focused ? 'library' : 'library-outline';
          } else if (route.name === 'Profile') {
            iconName = focused ? 'person' : 'person-outline';
          } else {
            iconName = 'help-outline';
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#6366f1',
        tabBarInactiveTintColor: 'gray',
        tabBarStyle: {
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
        headerStyle: {
          backgroundColor: '#6366f1',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      })}
    >
      <Tab.Screen
        name="Discover"
        component={DiscoverScreen}
        options={{
          title: 'Discover Books',
        }}
      />
      <Tab.Screen
        name="Ranking"
        component={RankingScreen}
        options={{
          title: 'Rankings',
        }}
      />
      <Tab.Screen
        name="Library"
        component={LibraryScreen}
        options={{
          title: 'My Library',
        }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          title: 'Profile',
        }}
      />
    </Tab.Navigator>
  );
}
