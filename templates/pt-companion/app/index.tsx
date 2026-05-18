import { Alert, Pressable, Text, View } from "react-native";
import { Stack } from "expo-router";

function handlePlaceholder(action: string) {
  console.log(`[pt-companion] placeholder tapped: ${action}`);
  Alert.alert(
    "Phase 0.3 wires this to your data.",
    `${action} will connect to your schedule and client list once you customise this template.`
  );
}

export default function HomeScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "PT Companion" }} />
      <View className="flex-1 items-center justify-center gap-y-4 px-6 bg-slate-50">
        <Text className="text-2xl font-bold text-slate-800 mb-2">
          Welcome back
        </Text>

        <Pressable
          className="w-full rounded-2xl bg-blue-700 py-4 items-center active:bg-blue-800"
          onPress={() => handlePlaceholder("Today's Workout")}
          accessibilityLabel="Today's Workout"
          accessibilityHint="Opens your workout plan for today"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-white">
            Today's Workout
          </Text>
        </Pressable>

        <Pressable
          className="w-full rounded-2xl bg-white border-2 border-blue-700 py-4 items-center active:bg-blue-50"
          onPress={() => handlePlaceholder("Check In With Client")}
          accessibilityLabel="Check In With Client"
          accessibilityHint="Opens the client check-in form"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-blue-700">
            Check In With Client
          </Text>
        </Pressable>
      </View>
    </>
  );
}
