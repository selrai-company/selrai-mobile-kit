import "../global.css";

import { useEffect, useState } from "react";
import { ActivityIndicator, View } from "react-native";
import { Stack, useRouter, useSegments } from "expo-router";

import { getCredentials } from "../lib/store";

export default function RootLayout() {
  const [ready, setReady] = useState(false);
  const [paired, setPaired] = useState(false);
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    (async () => {
      const creds = await getCredentials();
      setPaired(creds !== null);
      setReady(true);
    })();
  }, []);

  useEffect(() => {
    if (!ready) return;
    const onPair = segments[0] === "pair";
    if (!paired && !onPair) {
      router.replace("/pair");
    } else if (paired && onPair) {
      router.replace("/");
    }
  }, [ready, paired, segments, router]);

  if (!ready) {
    return (
      <View className="flex-1 items-center justify-center bg-slate-50">
        <ActivityIndicator size="large" color="#0f766e" />
      </View>
    );
  }

  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: "#0f766e" },
        headerTintColor: "#ffffff",
        headerTitleStyle: { fontWeight: "bold" },
        contentStyle: { backgroundColor: "#f8fafc" },
      }}
    />
  );
}
