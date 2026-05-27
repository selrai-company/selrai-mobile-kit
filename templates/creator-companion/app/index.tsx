import { useCallback, useEffect, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Pressable,
  RefreshControl,
  ScrollView,
  Text,
  View,
} from "react-native";
import { Stack, useRouter } from "expo-router";

import { getCredentials, clearCredentials } from "../lib/store";
import {
  ActionGateError,
  fetchDailyPrompt,
  fetchPostDraft,
  type DailyPromptResponse,
  type PostDraftResponse,
} from "../lib/ghl-client";

type CardState<T> =
  | { kind: "loading" }
  | { kind: "data"; value: T }
  | { kind: "gate"; message: string; retryAfterSeconds?: number }
  | { kind: "error"; message: string };

function classifyError<T>(reason: unknown): CardState<T> {
  if (reason instanceof ActionGateError) {
    return {
      kind: "gate",
      message: reason.message,
      retryAfterSeconds: reason.retryAfterSeconds,
    };
  }
  const message = reason instanceof Error ? reason.message : "Network error";
  return { kind: "error", message };
}

export default function HomeScreen() {
  const router = useRouter();
  const [prompt, setPrompt] = useState<CardState<DailyPromptResponse>>({ kind: "loading" });
  const [draft, setDraft] = useState<CardState<PostDraftResponse>>({ kind: "loading" });
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    const creds = await getCredentials();
    if (!creds) {
      router.replace("/pair");
      return;
    }

    setPrompt({ kind: "loading" });
    setDraft({ kind: "loading" });

    const [promptResult, draftResult] = await Promise.allSettled([
      fetchDailyPrompt(creds),
      fetchPostDraft(creds),
    ]);

    if (promptResult.status === "fulfilled") {
      setPrompt({ kind: "data", value: promptResult.value });
    } else {
      setPrompt(classifyError<DailyPromptResponse>(promptResult.reason));
    }
    if (draftResult.status === "fulfilled") {
      setDraft({ kind: "data", value: draftResult.value });
    } else {
      setDraft(classifyError<PostDraftResponse>(draftResult.reason));
    }
  }, [router]);

  useEffect(() => {
    load();
  }, [load]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      await load();
    } finally {
      setRefreshing(false);
    }
  }, [load]);

  const onUnpair = useCallback(() => {
    Alert.alert("Unpair this device?", "You will need to scan the QR again to re-pair.", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Unpair",
        style: "destructive",
        onPress: async () => {
          await clearCredentials();
          router.replace("/pair");
        },
      },
    ]);
  }, [router]);

  return (
    <>
      <Stack.Screen
        options={{
          title: "Creator Companion",
          headerRight: () => (
            <Pressable onPress={onUnpair} accessibilityLabel="Unpair this device">
              <Text className="text-white font-medium text-base mr-2">Unpair</Text>
            </Pressable>
          ),
        }}
      />
      <ScrollView
        className="flex-1 bg-slate-50 px-4 pt-4"
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#7e22ce" />
        }
      >
        <DailyPromptCard state={prompt} />
        <View className="h-4" />
        <PostDraftCard state={draft} />
        <View className="h-12" />
      </ScrollView>
    </>
  );
}

function DailyPromptCard({ state }: { state: CardState<DailyPromptResponse> }) {
  return (
    <View className="rounded-2xl bg-white border border-slate-200 p-5">
      <View className="flex-row items-center justify-between mb-3">
        <Text className="text-lg font-bold text-slate-800">Today's Prompt</Text>
        {state.kind === "data" && state.value.stub ? (
          <View className="rounded-full bg-amber-100 px-2 py-0.5">
            <Text className="text-xs text-amber-700">stub</Text>
          </View>
        ) : null}
      </View>
      {state.kind === "loading" ? (
        <View className="py-6 items-center">
          <ActivityIndicator color="#7e22ce" />
        </View>
      ) : state.kind === "gate" ? (
        <Text className="text-amber-700 text-sm">{state.message}</Text>
      ) : state.kind === "error" ? (
        <Text className="text-red-700 text-sm">Could not load. {state.message}</Text>
      ) : (
        <>
          <Text className="text-xs uppercase text-purple-700 font-semibold mb-2">
            {state.value.theme}
          </Text>
          <Text className="text-base text-slate-800 mb-3">{state.value.prompt}</Text>
          <View className="border-t border-slate-100 pt-3">
            <Text className="text-xs text-slate-500 mb-1">Suggested CTA</Text>
            <Text className="text-sm text-slate-700">{state.value.suggested_cta}</Text>
          </View>
        </>
      )}
    </View>
  );
}

function PostDraftCard({ state }: { state: CardState<PostDraftResponse> }) {
  return (
    <View className="rounded-2xl bg-white border border-slate-200 p-5">
      <View className="flex-row items-center justify-between mb-3">
        <Text className="text-lg font-bold text-slate-800">Draft Post</Text>
        {state.kind === "data" && state.value.stub ? (
          <View className="rounded-full bg-amber-100 px-2 py-0.5">
            <Text className="text-xs text-amber-700">stub</Text>
          </View>
        ) : null}
      </View>
      {state.kind === "loading" ? (
        <View className="py-6 items-center">
          <ActivityIndicator color="#7e22ce" />
        </View>
      ) : state.kind === "gate" ? (
        <Text className="text-amber-700 text-sm">{state.message}</Text>
      ) : state.kind === "error" ? (
        <Text className="text-red-700 text-sm">Could not load. {state.message}</Text>
      ) : (
        <>
          <Text className="text-xs uppercase text-purple-700 font-semibold mb-2">
            {state.value.channel}
          </Text>
          <Text className="text-base font-semibold text-slate-800 mb-2">
            {state.value.title}
          </Text>
          <Text className="text-sm text-slate-700 mb-3">{state.value.body}</Text>
          <View className="flex-row flex-wrap gap-1 mb-3">
            {state.value.suggested_hashtags.map((tag) => (
              <View key={tag} className="rounded-full bg-purple-100 px-2 py-0.5">
                <Text className="text-xs text-purple-800">{tag}</Text>
              </View>
            ))}
          </View>
          <View className="border-t border-slate-100 pt-3">
            <Text className="text-xs text-slate-500">
              Suggested schedule: {formatScheduleTime(state.value.suggested_schedule_iso)}
            </Text>
          </View>
        </>
      )}
    </View>
  );
}

function formatScheduleTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}
