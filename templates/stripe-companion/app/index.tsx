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
  fetchMrrSnapshot,
  fetchFailedPayments,
  type MrrSnapshotResponse,
  type FailedPaymentsResponse,
} from "../lib/stripe-client";

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
  const [mrr, setMrr] = useState<CardState<MrrSnapshotResponse>>({ kind: "loading" });
  const [failed, setFailed] = useState<CardState<FailedPaymentsResponse>>({ kind: "loading" });
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    const creds = await getCredentials();
    if (!creds) {
      router.replace("/pair");
      return;
    }

    setMrr({ kind: "loading" });
    setFailed({ kind: "loading" });

    const [mrrResult, failedResult] = await Promise.allSettled([
      fetchMrrSnapshot(creds),
      fetchFailedPayments(creds),
    ]);

    if (mrrResult.status === "fulfilled") {
      setMrr({ kind: "data", value: mrrResult.value });
    } else {
      setMrr(classifyError<MrrSnapshotResponse>(mrrResult.reason));
    }
    if (failedResult.status === "fulfilled") {
      setFailed({ kind: "data", value: failedResult.value });
    } else {
      setFailed(classifyError<FailedPaymentsResponse>(failedResult.reason));
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
          title: "Stripe Companion",
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
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#635bff" />
        }
      >
        <MrrCard state={mrr} />
        <View className="h-4" />
        <FailedPaymentsCard state={failed} />
        <View className="h-12" />
      </ScrollView>
    </>
  );
}

function MrrCard({ state }: { state: CardState<MrrSnapshotResponse> }) {
  return (
    <View className="rounded-2xl bg-white border border-slate-200 p-5">
      <View className="flex-row items-center justify-between mb-3">
        <Text className="text-lg font-bold text-slate-800">Monthly Recurring Revenue</Text>
        {state.kind === "data" && state.value.stub ? (
          <View className="rounded-full bg-amber-100 px-2 py-0.5">
            <Text className="text-xs text-amber-700">stub</Text>
          </View>
        ) : null}
      </View>
      {state.kind === "loading" ? (
        <View className="py-6 items-center">
          <ActivityIndicator color="#635bff" />
        </View>
      ) : state.kind === "gate" ? (
        <Text className="text-amber-700 text-sm">{state.message}</Text>
      ) : state.kind === "error" ? (
        <Text className="text-red-700 text-sm">Could not load. {state.message}</Text>
      ) : (
        <>
          <Text className="text-3xl font-bold text-slate-900">
            {formatMoney(state.value.mrr_cents, state.value.currency)}
          </Text>
          <View className="flex-row items-center mt-1 mb-3">
            <Text
              className={`text-sm font-semibold ${
                state.value.mom_delta_cents >= 0 ? "text-emerald-600" : "text-red-600"
              }`}
            >
              {state.value.mom_delta_cents >= 0 ? "+" : ""}
              {formatMoney(state.value.mom_delta_cents, state.value.currency)}
            </Text>
            <Text className="text-sm text-slate-500 ml-2">
              ({formatPct(state.value.mom_delta_pct)} MoM)
            </Text>
          </View>
          <View className="flex-row justify-between border-t border-slate-100 pt-3">
            <Stat label="Subscribers" value={String(state.value.active_subscribers)} />
            <Stat label="Subscriptions" value={String(state.value.active_subscriptions)} />
            <Stat label="Trialing" value={String(state.value.trialing)} />
          </View>
        </>
      )}
    </View>
  );
}

function FailedPaymentsCard({ state }: { state: CardState<FailedPaymentsResponse> }) {
  return (
    <View className="rounded-2xl bg-white border border-slate-200 p-5">
      <View className="flex-row items-center justify-between mb-3">
        <Text className="text-lg font-bold text-slate-800">Failed Payments</Text>
        {state.kind === "data" && state.value.stub ? (
          <View className="rounded-full bg-amber-100 px-2 py-0.5">
            <Text className="text-xs text-amber-700">stub</Text>
          </View>
        ) : null}
      </View>
      {state.kind === "loading" ? (
        <View className="py-6 items-center">
          <ActivityIndicator color="#635bff" />
        </View>
      ) : state.kind === "gate" ? (
        <Text className="text-amber-700 text-sm">{state.message}</Text>
      ) : state.kind === "error" ? (
        <Text className="text-red-700 text-sm">Could not load. {state.message}</Text>
      ) : state.value.total_failed_count === 0 ? (
        <Text className="text-base text-emerald-600">No failed payments. All clear.</Text>
      ) : (
        <>
          <Text className="text-sm text-slate-500 mb-3">
            {state.value.total_failed_count} failed,{" "}
            {formatMoney(state.value.total_failed_amount_cents, state.value.currency)} at risk
          </Text>
          {state.value.payments.map((p) => (
            <View key={p.id} className="border-t border-slate-100 py-2">
              <View className="flex-row items-center justify-between">
                <Text className="text-sm font-medium text-slate-900">{p.customer_label}</Text>
                <Text className="text-sm font-semibold text-slate-900">
                  {formatMoney(p.amount_cents, state.value.currency)}
                </Text>
              </View>
              <View className="flex-row items-center mt-1">
                <View
                  className={`rounded-full px-2 py-0.5 mr-2 ${
                    p.retry_safe ? "bg-emerald-100" : "bg-red-100"
                  }`}
                >
                  <Text
                    className={`text-xs ${p.retry_safe ? "text-emerald-700" : "text-red-700"}`}
                  >
                    {p.retry_safe ? "retry safe" : "needs new card"}
                  </Text>
                </View>
                <Text className="text-xs text-slate-500 flex-1">{p.operator_hint}</Text>
              </View>
            </View>
          ))}
        </>
      )}
    </View>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <View className="items-center">
      <Text className="text-lg font-bold text-slate-900">{value}</Text>
      <Text className="text-xs text-slate-500">{label}</Text>
    </View>
  );
}

function formatMoney(cents: number, currency: string): string {
  const amount = (cents / 100).toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return `${currency} ${amount}`;
}

function formatPct(pct: number): string {
  const sign = pct >= 0 ? "+" : "";
  return `${sign}${(pct * 100).toFixed(1)}%`;
}
