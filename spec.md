Build a standalone iOS app in SwiftUI for privacy-preserving credit score analysis:
- Feature: Extract iMessages on-device using Messages Export or manual text input.
- Input: 20-50 messages (text/JSON) containing financial data.
- Process: Parse messages, run Phi-3 Mini (MLX-Swift) on-device for Big Five personality traits and trustworthiness score, <2s latency.
- Output: Structured JSON (traits, score, explanations), signed with CryptoKit for verifiability.
- Backend: Send JSON to PostgreSQL via PostgresClientKit.
- Privacy: No raw data leaves iPhone; GDPR-compliant.
- UI: Text field, file picker for iMessage export, "Analyze" button, JSON display.
- Verifiability: Hash inputs+model weights, sign JSON; server verifies signature.
- Demo: Run on iPhone, show on-device processing and verified output.