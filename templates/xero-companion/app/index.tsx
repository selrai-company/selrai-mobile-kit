import { Alert, Pressable, Text, View } from "react-native";
import { Stack } from "expo-router";

function handlePlaceholder(action: string) {
  console.log(`[xero-companion] placeholder tapped: ${action}`);
  Alert.alert(
    "Phase 0.3 wires this to your Xero org.",
    `${action} will pull live data from the xero-proxy Cloudflare Worker once paired to your Xero Custom Connection.`
  );
}

export default function HomeScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "Xero Companion" }} />
      <View className="flex-1 items-center justify-center gap-y-4 px-6 bg-slate-50">
        <Text className="text-2xl font-bold text-slate-800 mb-2">
          Your numbers, at a glance
        </Text>

        <Pressable
          className="w-full rounded-2xl bg-teal-700 py-4 items-center active:bg-teal-800"
          onPress={() => handlePlaceholder("Today's Cash")}
          accessibilityLabel="Today's Cash"
          accessibilityHint="Opens your 90-day cash flow forecast from Xero"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-white">
            Today's Cash
          </Text>
        </Pressable>

        <Pressable
          className="w-full rounded-2xl bg-white border-2 border-teal-700 py-4 items-center active:bg-teal-50"
          onPress={() => handlePlaceholder("Who Owes Us")}
          accessibilityLabel="Who Owes Us"
          accessibilityHint="Opens the aged receivables report from Xero"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-teal-700">
            Who Owes Us
          </Text>
        </Pressable>
      </View>
    </>
  );
}
