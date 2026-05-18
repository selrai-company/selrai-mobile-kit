import { Alert, Pressable, Text, View } from "react-native";
import { Stack } from "expo-router";

function handlePlaceholder(action: string) {
  console.log(`[creator-companion] placeholder tapped: ${action}`);
  Alert.alert(
    "Phase 0.3 wires this to your data.",
    `${action} will connect to your content calendar and GHL account once you customise this template.`
  );
}

export default function HomeScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "Creator Companion" }} />
      <View className="flex-1 items-center justify-center gap-y-4 px-6 bg-slate-50">
        <Text className="text-2xl font-bold text-slate-800 mb-2">
          Let's create
        </Text>

        <Pressable
          className="w-full rounded-2xl bg-purple-800 py-4 items-center active:bg-purple-900"
          onPress={() => handlePlaceholder("Today's Prompt")}
          accessibilityLabel="Today's Prompt"
          accessibilityHint="Shows your content prompt for today"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-white">
            Today's Prompt
          </Text>
        </Pressable>

        <Pressable
          className="w-full rounded-2xl bg-white border-2 border-purple-800 py-4 items-center active:bg-purple-50"
          onPress={() => handlePlaceholder("Post to GHL")}
          accessibilityLabel="Post to GHL"
          accessibilityHint="Sends your content to GoHighLevel for scheduling"
          accessibilityRole="button"
        >
          <Text className="text-base font-semibold text-purple-800">
            Post to GHL
          </Text>
        </Pressable>
      </View>
    </>
  );
}
