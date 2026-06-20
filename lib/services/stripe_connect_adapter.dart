// Stripe Connect adapter — STUB.
//
// Each contractor connects their own Stripe account via Stripe Connect
// (Express or Standard accounts). The rest of the app talks to this
// adapter only; replacing the bodies below is the ONLY change needed
// when Stripe Connect is wired up.
//
// SETUP — what you must implement (server-side + here):
//   1. Create a Stripe platform account and enable Connect at
//      https://dashboard.stripe.com/connect/overview.
//   2. Add a backend endpoint (e.g. a Supabase Edge Function) that calls
//      Stripe's API to:
//        a. POST /v1/accounts            -> create an Express account
//        b. POST /v1/account_links       -> return an onboarding URL
//        c. GET  /v1/accounts/{id}       -> poll onboarding status
//        d. POST /v1/payment_intents     -> create a PaymentIntent with
//           transfer_data[destination] = <connected account id> and an
//           application_fee_amount if your platform takes a cut.
//   3. Store the connected account id on the contractor's profile row.
//   4. Replace the `throw UnimplementedError` bodies below with calls
//      to that endpoint.
//   5. Add the flutter_stripe package (https://pub.dev/packages/flutter_stripe)
//      and open the onboarding URL via url_launcher or an in-app webview.

class StripeOnboardingLink {
  final Uri url;
  final String connectedAccountId;
  const StripeOnboardingLink({required this.url, required this.connectedAccountId});
}

class StripePaymentResult {
  final String paymentIntentId;
  final String status;
  const StripePaymentResult({required this.paymentIntentId, required this.status});
}

class StripeConnectAdapter {
  /// Creates (or resumes) an Express account for the current contractor
  /// and returns a hosted onboarding URL.
  Future<StripeOnboardingLink> startOnboarding({
    required String contractorId,
    required String email,
  }) async {
    // TODO: call your backend endpoint wrapping Stripe /v1/accounts + /v1/account_links.
    throw UnimplementedError('StripeConnectAdapter.startOnboarding — see file header.');
  }

  /// Returns true once the contractor's connected account is fully onboarded.
  Future<bool> isOnboarded(String connectedAccountId) async {
    // TODO: call backend -> Stripe GET /v1/accounts/{id} and check charges_enabled.
    throw UnimplementedError('StripeConnectAdapter.isOnboarded — see file header.');
  }

  /// Charges a customer and routes funds to the contractor's connected account.
  Future<StripePaymentResult> charge({
    required int amountCents,
    required String currency,
    required String connectedAccountId,
    int applicationFeeCents = 0,
  }) async {
    // TODO: call backend -> Stripe POST /v1/payment_intents with transfer_data[destination].
    throw UnimplementedError('StripeConnectAdapter.charge — see file header.');
  }
}
