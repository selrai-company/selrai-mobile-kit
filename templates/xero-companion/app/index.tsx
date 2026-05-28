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
  fetchCashFlow,
  fetchArAgeing,
  type CashFlowResponse,
  type ArAgeingResponse,
} from "../lib/xero-client";

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
  const message =
    reason instanceof Error ? reason.message : "Network error";
  return { kind: "error", message };
}

export default function HomeScreen() {
  const router = useRouter();
  const [cashFlow, setCashFlow] = useState<CardState<CashFlowResponse>>({ kind: "loading" });
  const [arAgeing, setArAgeing] = useState<CardState<ArAgeingResponse>>({ kind: "loading" });
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    const creds = await getCredentials();
    if (!creds) {
      router.replace("/pair");
      return;
    }

    setCashFlow({ kind: "loading" });
    setArAgeing({ kind: "loading" });

    const [cfResult, arResult] = await Promise.allSettled([
      fetchCashFlow(creds),
      fetchArAgeing(creds),
    ]);

    if (cfResult.status === "fulfilled") {
      setCashFlow({ kind: "data", value: cfResult.value });
    } else {
      setCashFlow(classifyError<CashFlowResponse>(cfResult.reason));
    }
    if (arResult.status === "fulfilled") {
      setArAgeing({ kind: "data", value: arResult.value });
    } else {
      setArAgeing(classifyError<ArAgeingResponse>(arResult.reason));
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
          title: "Xero Companion",
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
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#0f766e" />
        }
      >
        <CashFlowCard state={cashFlow} />
        <View className="h-4" />
        <ArAgeingCard state={arAgeing} />
        <View className="h-12" />
      </ScrollView>
    </>
  );
}

function CashFlowCard({ state }: { state: CardState<CashFlowResponse> }) {
  return (
    <View className="rounded-2xl bg-white border border-slate-200 p-5">
      <View className="flex-row items-center justify-between mb-3">
        <Text className="text-lg font-bold text-slate-800">Today's Cash</Text>
        {state.kind === "data" && state.value.stale ? (
          <View className="rounded-full bg-amber-100 px-2 py-0.5">
            <Text className="text-xs text-amber-700">cached</Text>
          </View>
        ) : null}
      </View>
      {state.kind === "loading" ? (
        <View className="py-6 items-center">
          <ActivityIndicator color="#0f766e" />
        </View>
      ) : state.kind === "gate" ? (
        <Text className="text-amber-700 text-sm">{state.message}</Text>
      ) : state.kind === "error" ? (
        <Text className="text-red-700 text-sm">Could not load. {state.message}</Text>
      ) : (
        <>
          <Text className="text-3xl font-bold text-teal-700">
            {formatCurrency(state.value.balance_today, state.value.currency)}
          </Text>
          <Text className="text-sm text-slate-500 mt-1">
            Projected 90 days: {formatCurrency(state.value.projected_90d, state.value.currency)}
          </Text>
          {state.value.stub ? (
            <Text className="text-xs text-slate-400 mt-2">Stub data (Worker not yet wired to Xero)</Text>
          ) : null}
        </>
      )}
    </View>
  );
}

function ArAgeingCard({ state }: { state: CardState<ArAgeingResponse> }) {
  return (
    <View className="rounded-2xl bg-white border border-slate-200 p-5">
      <View className="flex-row items-center justify-between mb-3">
        <Text className="text-lg font-bold text-slate-800">Who Owes Us</Text>
        {state.kind === "data" && state.value.stale ? (
          <View className="rounded-full bg-amber-100 px-2 py-0.5">
            <Text className="text-xs text-amber-700">cached</Text>
          </View>
        ) : null}
      </View>
      {state.kind === "loading" ? (
        <View className="py-6 items-center">
          <ActivityIndicator color="#0f766e" />
        </View>
      ) : state.kind === "gate" ? (
        <Text className="text-amber-700 text-sm">{state.message}</Text>
      ) : state.kind === "error" ? (
        <Text className="text-red-700 text-sm">Could not load. {state.message}</Text>
      ) : state.value.total_overdue === 0 ? (
        <Text className="text-base text-teal-700">All paid up. Nothing overdue.</Text>
      ) : (
        <>
          <Text className="text-3xl font-bold text-teal-700">
            {formatCurrency(state.value.total_overdue, state.value.currency)}
          </Text>
          <Text className="text-sm text-slate-500 mt-1 mb-3">Total overdue</Text>
          {state.value.buckets
            .filter((b) => b.total > 0)
            .map((b) => (
              <View key={b.days} className="flex-row justify-between py-1 border-t border-slate-100">
                <Text className="text-sm text-slate-700">{b.days} days</Text>
                <Text className="text-sm font-medium text-slate-900">
                  {formatCurrency(b.total, state.value.currency)}
                </Text>
              </View>
            ))}
        </>
      )}
    </View>
  );
}

function formatCurrency(amount: number, currency: string): string {
  return `${currency} ${amount.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
}
