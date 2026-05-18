import { Alert, Pressable, Text, View } from "react-native";
import { Stack } from "expo-router";

function handlePlaceholder(action: string) {
  console.log(`[service-quote] placeholder tapped: ${action}`);
  Alert.alert(
    "Phase 0.3 wires this to your data.",
    `${action} will connect to your job list and quoting workflow once you customise this template.`
  );
}

export default function HomeScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "Service Quote" }} />
      <View className="flex-1 items-center justify-center gap-y-4 px-6 bg-slate-50">
        <Text className="text-2xl font-bold text-slate-800 mb-2">
          What do you need?
        </Text>

        <Pressable
          className="w-full rounded-2xl bg-green-700 py-4 items-center active:bg-green-800"
          onPress={() => handlePlaceholder("New Quote")}
          accessibilityLabel="New Quote"
          accessibilityHint="Starts a new quote for a job"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-white">
            New Quote
          </Text>
        </Pressable>

        <Pressable
          className="w-full rounded-2xl bg-white border-2 border-green-700 py-4 items-center active:bg-green-50"
          onPress={() => handlePlaceholder("Today's Jobs")}
          accessibilityLabel="Today's Jobs"
          accessibilityHint="Shows all jobs scheduled for today"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-green-700">
            Today's Jobs
          </Text>
        </Pressable>
      </View>
    </>
  );
}
