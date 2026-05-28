import { useCallback, useState } from "react";
import { Alert, Pressable, Text, TextInput, View } from "react-native";
import { Stack, useRouter } from "expo-router";
import { CameraView, useCameraPermissions } from "expo-camera";
import * as Haptics from "expo-haptics";

import { saveCredentials } from "../lib/store";
import { parsePairUri } from "../lib/stripe-client";

type PairMode = "camera" | "paste";

export default function PairScreen() {
  const router = useRouter();
  const [mode, setMode] = useState<PairMode>("camera");
  const [permission, requestPermission] = useCameraPermissions();
  const [pasteInput, setPasteInput] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [scanned, setScanned] = useState(false);

  const onPair = useCallback(
    async (uri: string) => {
      const creds = parsePairUri(uri);
      if (!creds) {
        setError("Invalid pair URI. Check the QR code or paste the full stripeproxy:// link.");
        return;
      }
      await saveCredentials(creds);
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      router.replace("/");
    },
    [router],
  );

  const onScan = useCallback(
    ({ data }: { data: string }) => {
      if (scanned) return;
      setScanned(true);
      onPair(data);
    },
    [scanned, onPair],
  );

  const onPasteSubmit = useCallback(() => {
    setError(null);
    onPair(pasteInput.trim());
  }, [pasteInput, onPair]);

  return (
    <>
      <Stack.Screen options={{ title: "Pair Stripe Companion" }} />
      <View className="flex-1 bg-slate-50 px-5 pt-5">
        <Text className="text-2xl font-bold text-slate-800 mb-2">
          Pair this app to your Stripe proxy
        </Text>
        <Text className="text-base text-slate-600 mb-5">
          Scan the QR your operator printed from cloud/register.sh, or paste the pair link below.
        </Text>

        <View className="flex-row mb-4 rounded-lg overflow-hidden border border-indigo-600">
          <Pressable
            onPress={() => setMode("camera")}
            className={`flex-1 py-2 items-center ${mode === "camera" ? "bg-indigo-600" : "bg-white"}`}
            accessibilityRole="button"
            accessibilityLabel="Scan QR code"
          >
            <Text className={`font-medium ${mode === "camera" ? "text-white" : "text-indigo-700"}`}>
              Scan QR
            </Text>
          </Pressable>
          <Pressable
            onPress={() => setMode("paste")}
            className={`flex-1 py-2 items-center ${mode === "paste" ? "bg-indigo-600" : "bg-white"}`}
            accessibilityRole="button"
            accessibilityLabel="Paste pair URI instead"
          >
            <Text className={`font-medium ${mode === "paste" ? "text-white" : "text-indigo-700"}`}>
              Paste URI
            </Text>
          </Pressable>
        </View>

        {mode === "camera" ? (
          <View className="h-80 rounded-2xl overflow-hidden border border-indigo-600">
            {!permission ? (
              <View className="flex-1 items-center justify-center bg-slate-100">
                <Text className="text-slate-600">Loading camera...</Text>
              </View>
            ) : !permission.granted ? (
              <View className="flex-1 items-center justify-center bg-slate-100 px-4">
                <Text className="text-slate-700 text-center mb-3">
                  We need camera access to scan the pair QR.
                </Text>
                <Pressable
                  onPress={() => {
                    requestPermission().catch((e) =>
                      Alert.alert("Permission error", String(e)),
                    );
                  }}
                  className="rounded-2xl bg-indigo-600 px-4 py-3"
                  accessibilityRole="button"
                  accessibilityLabel="Grant camera permission"
                >
                  <Text className="text-white font-semibold">Allow camera</Text>
                </Pressable>
              </View>
            ) : (
              <CameraView
                onBarcodeScanned={scanned ? undefined : onScan}
                barcodeScannerSettings={{ barcodeTypes: ["qr"] }}
                style={{ flex: 1 }}
              />
            )}
          </View>
        ) : (
          <View>
            <Text className="text-sm text-slate-700 mb-2">
              Paste the full pair URI (begins with stripeproxy://pair?...)
            </Text>
            <TextInput
              className="rounded-2xl bg-white border border-slate-300 p-3 mb-3 text-sm"
              value={pasteInput}
              onChangeText={setPasteInput}
              autoCapitalize="none"
              autoCorrect={false}
              multiline={false}
              placeholder="stripeproxy://pair?url=...&amp;slug=...&amp;secret=..."
              accessibilityLabel="Pair URI input"
            />
            <Pressable
              onPress={onPasteSubmit}
              className="rounded-2xl bg-indigo-600 py-3 items-center"
              accessibilityRole="button"
              accessibilityLabel="Connect with pasted URI"
            >
              <Text className="text-white font-semibold">Connect</Text>
            </Pressable>
          </View>
        )}

        {error ? <Text className="text-red-700 text-sm mt-3">{error}</Text> : null}
      </View>
    </>
  );
}
