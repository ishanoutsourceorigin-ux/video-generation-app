import 'package:flutter_test/flutter_test.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';

/// PRODUCTION-READY PAYMENT SYSTEM TESTS
/// Testing all pricing tiers and credit calculations
///
/// REQUIREMENTS:
/// - 1 credit = 1 minute of avatar video
/// - Video duration rounds UP (1:01 = 2 credits)
/// - 3 Subscription tiers (only one active at a time)
/// - 3 Credit top-ups (can buy anytime)
/// - 3 Faceless LTD tiers (Stripe webhook)

void main() {
  group('🎯 CREDIT SYSTEM - Core Calculations', () {
    test('1 credit = 1 minute (exact duration)', () {
      final credits = CreditSystemService.calculateRequiredCredits(
        videoType: 'avatar-video',
        durationMinutes: 1,
        durationSeconds: 0,
      );
      expect(
        credits,
        equals(1),
        reason: '1 minute should cost exactly 1 credit',
      );
    });

    test('1 minute 1 second = 2 credits (rounds up)', () {
      final credits = CreditSystemService.calculateRequiredCredits(
        videoType: 'avatar-video',
        durationMinutes: 1,
        durationSeconds: 1,
      );
      expect(
        credits,
        equals(2),
        reason: 'Any seconds over the minute rounds UP',
      );
    });

    test('2 minutes exact = 2 credits', () {
      final credits = CreditSystemService.calculateRequiredCredits(
        videoType: 'avatar-video',
        durationMinutes: 2,
        durationSeconds: 0,
      );
      expect(credits, equals(2));
    });

    test('2 minutes 30 seconds = 3 credits (rounds up)', () {
      final credits = CreditSystemService.calculateRequiredCredits(
        videoType: 'avatar-video',
        durationMinutes: 2,
        durationSeconds: 30,
      );
      expect(credits, equals(3));
    });

    test('0 minutes = 1 credit minimum', () {
      final credits = CreditSystemService.calculateRequiredCredits(
        videoType: 'avatar-video',
        durationMinutes: 0,
        durationSeconds: 0,
      );
      expect(
        credits,
        equals(1),
        reason: 'Minimum 1 credit even for 0 duration',
      );
    });

    test('Credits per minute constant = 1', () {
      expect(CreditSystemService.avatarVideoCreditsPerMinute, equals(1));
    });
  });

  group('💳 SUBSCRIPTION PLANS - Monthly (Only One Active)', () {
    test('Basic Plan: 30 videos, \$27/month', () {
      final plan = CreditSystemService.subscriptionPlans['basic'];

      expect(plan, isNotNull);
      expect(plan!['videos'], equals(30), reason: '30 videos per month');
      expect(plan['price'], equals(27.0), reason: 'Price is \$27');
      expect(plan['priceDisplay'], equals('\$27'));
      expect(plan['type'], equals('subscription'));
      expect(plan['billingPeriod'], equals('month'));
      expect(plan['name'], equals('Basic'));
    });

    test('Starter Plan: 60 videos, \$47/month (Popular)', () {
      final plan = CreditSystemService.subscriptionPlans['starter'];

      expect(plan, isNotNull);
      expect(plan!['videos'], equals(60), reason: '60 videos per month');
      expect(plan['price'], equals(47.0), reason: 'Price is \$47');
      expect(plan['priceDisplay'], equals('\$47'));
      expect(plan['type'], equals('subscription'));
      expect(plan['billingPeriod'], equals('month'));
      expect(
        plan['popular'],
        equals(true),
        reason: 'Starter is marked as popular',
      );
    });

    test('Pro Plan: 150 videos, \$97/month', () {
      final plan = CreditSystemService.subscriptionPlans['pro'];

      expect(plan, isNotNull);
      expect(plan!['videos'], equals(150), reason: '150 videos per month');
      expect(plan['price'], equals(97.0), reason: 'Price is \$97');
      expect(plan['priceDisplay'], equals('\$97'));
      expect(plan['type'], equals('subscription'));
      expect(plan['billingPeriod'], equals('month'));
    });

    test('All 3 subscription plans exist', () {
      expect(CreditSystemService.subscriptionPlans.length, equals(3));
      expect(
        CreditSystemService.subscriptionPlans.keys,
        containsAll(['basic', 'starter', 'pro']),
      );
    });

    test('Subscription plan per-video cost analysis', () {
      final basic = CreditSystemService.subscriptionPlans['basic']!;
      final starter = CreditSystemService.subscriptionPlans['starter']!;
      final pro = CreditSystemService.subscriptionPlans['pro']!;

      // Calculate per-video cost
      final basicPerVideo = basic['price'] / basic['videos'];
      final starterPerVideo = starter['price'] / starter['videos'];
      final proPerVideo = pro['price'] / pro['videos'];

      // Basic: $27 / 30 = $0.90 per video
      expect(basicPerVideo, closeTo(0.90, 0.01));

      // Starter: $47 / 60 = $0.78 per video
      expect(starterPerVideo, closeTo(0.78, 0.02));

      // Pro: $97 / 150 = $0.65 per video
      expect(proPerVideo, closeTo(0.65, 0.01));

      // Pro should be cheapest per video
      expect(proPerVideo < starterPerVideo, isTrue);
      expect(starterPerVideo < basicPerVideo, isTrue);
    });
  });

  group('💰 CREDIT TOP-UPS - In-App Purchases (Can Buy Anytime)', () {
    test('10 Credits Top-up: \$10', () {
      final topup = CreditSystemService.creditTopups['credits_10'];

      expect(topup, isNotNull);
      expect(topup!['credits'], equals(10));
      expect(topup['price'], equals(10.0));
      expect(topup['priceDisplay'], equals('\$10'));
      expect(topup['type'], equals('topup'));
      expect(topup['name'], equals('10 Credits'));
    });

    test('20 Credits Top-up: \$18 (Save \$2)', () {
      final topup = CreditSystemService.creditTopups['credits_20'];

      expect(topup, isNotNull);
      expect(topup!['credits'], equals(20));
      expect(topup['price'], equals(18.0));
      expect(topup['priceDisplay'], equals('\$18'));
      expect(topup['type'], equals('topup'));
      expect(topup['savings'], equals('\$2 off'));

      // Verify savings: 20 credits at $1 each = $20, but priced at $18
      final expectedPrice = 20.0; // 20 credits × $1
      final actualSavings = expectedPrice - topup['price'];
      expect(actualSavings, equals(2.0), reason: 'Should save \$2');
    });

    test('30 Credits Top-up: \$25 (Save \$5, Most Popular)', () {
      final topup = CreditSystemService.creditTopups['credits_30'];

      expect(topup, isNotNull);
      expect(topup!['credits'], equals(30));
      expect(topup['price'], equals(25.0));
      expect(topup['priceDisplay'], equals('\$25'));
      expect(topup['type'], equals('topup'));
      expect(topup['savings'], equals('\$5 off'));
      expect(topup['popular'], equals(true));

      // Verify savings: 30 credits at $1 each = $30, but priced at $25
      final expectedPrice = 30.0;
      final actualSavings = expectedPrice - topup['price'];
      expect(actualSavings, equals(5.0), reason: 'Should save \$5');
    });

    test('All 3 credit top-ups exist', () {
      expect(CreditSystemService.creditTopups.length, equals(3));
      expect(
        CreditSystemService.creditTopups.keys,
        containsAll(['credits_10', 'credits_20', 'credits_30']),
      );
    });

    test('Top-up per-credit cost analysis', () {
      final topup10 = CreditSystemService.creditTopups['credits_10']!;
      final topup20 = CreditSystemService.creditTopups['credits_20']!;
      final topup30 = CreditSystemService.creditTopups['credits_30']!;

      // 10 credits: $10 / 10 = $1.00 per credit
      final cost10 = topup10['price'] / topup10['credits'];
      expect(cost10, equals(1.0));

      // 20 credits: $18 / 20 = $0.90 per credit
      final cost20 = topup20['price'] / topup20['credits'];
      expect(cost20, equals(0.9));

      // 30 credits: $25 / 30 = $0.833... per credit
      final cost30 = topup30['price'] / topup30['credits'];
      expect(cost30, closeTo(0.833, 0.01));

      // Larger packages should be cheaper per credit
      expect(cost30 < cost20, isTrue);
      expect(cost20 < cost10, isTrue);
    });
  });

  group('🌐 FACELESS LTD - Stripe Webhook Plans', () {
    test('Faceless Basic: \$60 → 30 videos/month', () {
      final plan = CreditSystemService.facelessLtdPlans['faceless_basic'];

      expect(plan, isNotNull);
      expect(plan!['videos'], equals(30));
      expect(plan['price'], equals(60.0));
      expect(plan['stripeAmount'], equals(6000), reason: 'Amount in cents');
      expect(plan['type'], equals('faceless_ltd'));
      expect(plan['billingPeriod'], equals('month'));
    });

    test('Faceless Starter: \$97 → 60 videos/month', () {
      final plan = CreditSystemService.facelessLtdPlans['faceless_starter'];

      expect(plan, isNotNull);
      expect(plan!['videos'], equals(60));
      expect(plan['price'], equals(97.0));
      expect(plan['stripeAmount'], equals(9700), reason: 'Amount in cents');
      expect(plan['type'], equals('faceless_ltd'));
    });

    test('Faceless Pro: \$197 → 150 videos/month', () {
      final plan = CreditSystemService.facelessLtdPlans['faceless_pro'];

      expect(plan, isNotNull);
      expect(plan!['videos'], equals(150));
      expect(plan['price'], equals(197.0));
      expect(plan['stripeAmount'], equals(19700), reason: 'Amount in cents');
      expect(plan['type'], equals('faceless_ltd'));
    });

    test('All 3 Faceless LTD plans exist', () {
      expect(CreditSystemService.facelessLtdPlans.length, equals(3));
      expect(
        CreditSystemService.facelessLtdPlans.keys,
        containsAll(['faceless_basic', 'faceless_starter', 'faceless_pro']),
      );
    });

    test('Faceless plan detection by Stripe amount', () {
      // Test $60 payment
      final plan60 = CreditSystemService.getFacelessPlanByAmount(6000);
      expect(plan60, isNotNull);
      expect(plan60!['videos'], equals(30));

      // Test $97 payment
      final plan97 = CreditSystemService.getFacelessPlanByAmount(9700);
      expect(plan97, isNotNull);
      expect(plan97!['videos'], equals(60));

      // Test $197 payment
      final plan197 = CreditSystemService.getFacelessPlanByAmount(19700);
      expect(plan197, isNotNull);
      expect(plan197!['videos'], equals(150));

      // Test invalid amount
      final planInvalid = CreditSystemService.getFacelessPlanByAmount(5000);
      expect(planInvalid, isNull, reason: 'Unknown amount should return null');
    });

    test('Faceless per-video cost (highest pricing tier)', () {
      final basic = CreditSystemService.facelessLtdPlans['faceless_basic']!;
      final starter = CreditSystemService.facelessLtdPlans['faceless_starter']!;
      final pro = CreditSystemService.facelessLtdPlans['faceless_pro']!;

      // Basic: $60 / 30 = $2.00 per video
      final basicPerVideo = basic['price'] / basic['videos'];
      expect(basicPerVideo, equals(2.0));

      // Starter: $97 / 60 = $1.617 per video
      final starterPerVideo = starter['price'] / starter['videos'];
      expect(starterPerVideo, closeTo(1.617, 0.01));

      // Pro: $197 / 150 = $1.313 per video
      final proPerVideo = pro['price'] / pro['videos'];
      expect(proPerVideo, closeTo(1.313, 0.01));

      // Should be more expensive than subscriptions (premium channel)
      final subBasic = CreditSystemService.subscriptionPlans['basic']!;
      final subBasicPerVideo = subBasic['price'] / subBasic['videos'];
      expect(
        basicPerVideo > subBasicPerVideo,
        isTrue,
        reason: 'Faceless pricing is higher than subscription',
      );
    });
  });

  group('🔍 PRICING COMPARISON - All Tiers', () {
    test('Per-video cost comparison (30 videos)', () {
      // All plans offering 30 videos
      final subBasic = CreditSystemService.subscriptionPlans['basic']!;
      final facelessBasic =
          CreditSystemService.facelessLtdPlans['faceless_basic']!;

      final subCost =
          subBasic['price'] / subBasic['videos']; // $27 / 30 = $0.90
      final facelessCost =
          facelessBasic['price'] / facelessBasic['videos']; // $60 / 30 = $2.00

      expect(subCost, closeTo(0.90, 0.01));
      expect(facelessCost, equals(2.0));

      // Subscription should be better value
      expect(subCost < facelessCost, isTrue);

      // Faceless is 2.22x more expensive
      final priceMultiplier = facelessCost / subCost;
      expect(priceMultiplier, closeTo(2.22, 0.1));
    });

    test('Best value per video: Pro Subscription', () {
      final allPlans = [
        {'name': 'Sub Basic', 'price': 27.0, 'videos': 30},
        {'name': 'Sub Starter', 'price': 47.0, 'videos': 60},
        {'name': 'Sub Pro', 'price': 97.0, 'videos': 150},
        {'name': 'Topup 10', 'price': 10.0, 'videos': 10},
        {'name': 'Topup 20', 'price': 18.0, 'videos': 20},
        {'name': 'Topup 30', 'price': 25.0, 'videos': 30},
        {'name': 'Faceless Basic', 'price': 60.0, 'videos': 30},
        {'name': 'Faceless Starter', 'price': 97.0, 'videos': 60},
        {'name': 'Faceless Pro', 'price': 197.0, 'videos': 150},
      ];

      final costsPerVideo = allPlans.map((plan) {
        return {
          'name': plan['name'],
          'costPerVideo': (plan['price'] as double) / (plan['videos'] as int),
        };
      }).toList();

      // Sort by cost per video
      costsPerVideo.sort(
        (a, b) => (a['costPerVideo'] as double).compareTo(
          b['costPerVideo'] as double,
        ),
      );

      // Cheapest should be Pro Subscription: $97 / 150 = $0.65
      expect(costsPerVideo.first['name'], equals('Sub Pro'));
      expect(costsPerVideo.first['costPerVideo'], closeTo(0.65, 0.01));

      // Most expensive should be Faceless Basic: $60 / 30 = $2.00
      expect(costsPerVideo.last['name'], equals('Faceless Basic'));
      expect(costsPerVideo.last['costPerVideo'], equals(2.0));
    });

    test('Subscription + Top-up combination works', () {
      // User has Pro subscription (150 videos) + wants to add 30 more credits
      final proSub = CreditSystemService.subscriptionPlans['pro']!;
      final topup30 = CreditSystemService.creditTopups['credits_30']!;

      final totalVideos =
          proSub['videos'] + topup30['credits']; // 150 + 30 = 180
      final totalCost = proSub['price'] + topup30['price']; // $97 + $25 = $122

      expect(totalVideos, equals(180));
      expect(totalCost, equals(122.0));

      // Per video cost for this combo
      final comboPerVideo = totalCost / totalVideos;
      expect(
        comboPerVideo,
        closeTo(0.678, 0.01),
        reason: 'Combo should maintain good per-video value',
      );
    });
  });

  group('💡 PROFITABILITY - A2E API Cost Analysis', () {
    const a2eCostPerMinute = 0.27; // $0.27 per minute (360 credits)

    test('Subscription Basic profit margin', () {
      final plan = CreditSystemService.subscriptionPlans['basic']!;
      final revenue = plan['price'] as double; // $27
      final videos = plan['videos'] as int; // 30
      final a2eCost = videos * a2eCostPerMinute; // 30 × $0.27 = $8.10

      final grossProfit = revenue - a2eCost; // $27 - $8.10 = $18.90
      final margin = (grossProfit / revenue) * 100; // 70%

      expect(grossProfit, closeTo(18.90, 0.1));
      expect(margin, closeTo(70.0, 1.0));
    });

    test('Subscription Starter profit margin', () {
      final plan = CreditSystemService.subscriptionPlans['starter']!;
      final revenue = plan['price'] as double; // $47
      final videos = plan['videos'] as int; // 60
      final a2eCost = videos * a2eCostPerMinute; // 60 × $0.27 = $16.20

      final grossProfit = revenue - a2eCost; // $47 - $16.20 = $30.80
      final margin = (grossProfit / revenue) * 100; // 65.5%

      expect(grossProfit, closeTo(30.80, 0.1));
      expect(margin, closeTo(65.5, 1.0));
    });

    test('Subscription Pro profit margin', () {
      final plan = CreditSystemService.subscriptionPlans['pro']!;
      final revenue = plan['price'] as double; // $97
      final videos = plan['videos'] as int; // 150
      final a2eCost = videos * a2eCostPerMinute; // 150 × $0.27 = $40.50

      final grossProfit = revenue - a2eCost; // $97 - $40.50 = $56.50
      final margin = (grossProfit / revenue) * 100; // 58.2%

      expect(grossProfit, closeTo(56.50, 0.1));
      expect(margin, closeTo(58.2, 1.0));
    });

    test('Top-up 10 credits profit margin', () {
      final topup = CreditSystemService.creditTopups['credits_10']!;
      final revenue = topup['price'] as double; // $10
      final credits = topup['credits'] as int; // 10
      final a2eCost = credits * a2eCostPerMinute; // 10 × $0.27 = $2.70

      final grossProfit = revenue - a2eCost; // $10 - $2.70 = $7.30
      final margin = (grossProfit / revenue) * 100; // 73%

      expect(grossProfit, closeTo(7.30, 0.1));
      expect(margin, closeTo(73.0, 1.0));
    });

    test('Faceless Basic profit margin (highest)', () {
      final plan = CreditSystemService.facelessLtdPlans['faceless_basic']!;
      final revenue = plan['price'] as double; // $60
      final videos = plan['videos'] as int; // 30
      final a2eCost = videos * a2eCostPerMinute; // 30 × $0.27 = $8.10

      final grossProfit = revenue - a2eCost; // $60 - $8.10 = $51.90
      final margin = (grossProfit / revenue) * 100; // 86.5%

      expect(grossProfit, closeTo(51.90, 0.1));
      expect(margin, closeTo(86.5, 1.0));

      // Faceless should have highest margin
      expect(margin > 70.0, isTrue, reason: 'Faceless LTD has premium pricing');
    });

    test('All plans are profitable (minimum 58% margin)', () {
      const minAcceptableMargin = 58.0;

      // Test all subscription plans
      for (var entry in CreditSystemService.subscriptionPlans.entries) {
        final plan = entry.value;
        final revenue = plan['price'] as double;
        final videos = plan['videos'] as int;
        final a2eCost = videos * a2eCostPerMinute;
        final margin = ((revenue - a2eCost) / revenue) * 100;

        expect(
          margin,
          greaterThanOrEqualTo(minAcceptableMargin),
          reason: '${entry.key} should be profitable',
        );
      }

      // Test all top-ups
      for (var entry in CreditSystemService.creditTopups.entries) {
        final topup = entry.value;
        final revenue = topup['price'] as double;
        final credits = topup['credits'] as int;
        final a2eCost = credits * a2eCostPerMinute;
        final margin = ((revenue - a2eCost) / revenue) * 100;

        expect(
          margin,
          greaterThanOrEqualTo(minAcceptableMargin),
          reason: '${entry.key} should be profitable',
        );
      }

      // Test all Faceless plans
      for (var entry in CreditSystemService.facelessLtdPlans.entries) {
        final plan = entry.value;
        final revenue = plan['price'] as double;
        final videos = plan['videos'] as int;
        final a2eCost = videos * a2eCostPerMinute;
        final margin = ((revenue - a2eCost) / revenue) * 100;

        expect(
          margin,
          greaterThanOrEqualTo(minAcceptableMargin),
          reason: '${entry.key} should be profitable',
        );
      }
    });
  });

  group('📋 PRODUCTION READINESS', () {
    test('All required plan types exist', () {
      expect(CreditSystemService.subscriptionPlans.isNotEmpty, isTrue);
      expect(CreditSystemService.creditTopups.isNotEmpty, isTrue);
      expect(CreditSystemService.facelessLtdPlans.isNotEmpty, isTrue);
    });

    test('All plans have required fields', () {
      // Check subscriptions
      for (var plan in CreditSystemService.subscriptionPlans.values) {
        expect(plan.containsKey('name'), isTrue);
        expect(plan.containsKey('videos'), isTrue);
        expect(plan.containsKey('price'), isTrue);
        expect(plan.containsKey('priceDisplay'), isTrue);
        expect(plan.containsKey('type'), isTrue);
        expect(plan.containsKey('billingPeriod'), isTrue);
      }

      // Check top-ups
      for (var topup in CreditSystemService.creditTopups.values) {
        expect(topup.containsKey('name'), isTrue);
        expect(topup.containsKey('credits'), isTrue);
        expect(topup.containsKey('price'), isTrue);
        expect(topup.containsKey('priceDisplay'), isTrue);
        expect(topup.containsKey('type'), isTrue);
      }

      // Check Faceless LTD
      for (var plan in CreditSystemService.facelessLtdPlans.values) {
        expect(plan.containsKey('name'), isTrue);
        expect(plan.containsKey('videos'), isTrue);
        expect(plan.containsKey('price'), isTrue);
        expect(plan.containsKey('stripeAmount'), isTrue);
        expect(plan.containsKey('type'), isTrue);
      }
    });

    test('Price displays are formatted correctly', () {
      // Subscriptions
      expect(
        CreditSystemService.subscriptionPlans['basic']!['priceDisplay'],
        equals('\$27'),
      );
      expect(
        CreditSystemService.subscriptionPlans['starter']!['priceDisplay'],
        equals('\$47'),
      );
      expect(
        CreditSystemService.subscriptionPlans['pro']!['priceDisplay'],
        equals('\$97'),
      );

      // Top-ups
      expect(
        CreditSystemService.creditTopups['credits_10']!['priceDisplay'],
        equals('\$10'),
      );
      expect(
        CreditSystemService.creditTopups['credits_20']!['priceDisplay'],
        equals('\$18'),
      );
      expect(
        CreditSystemService.creditTopups['credits_30']!['priceDisplay'],
        equals('\$25'),
      );
    });

    test('Stripe amounts are in cents (integer)', () {
      final basic = CreditSystemService
          .facelessLtdPlans['faceless_basic']!['stripeAmount'];
      final starter = CreditSystemService
          .facelessLtdPlans['faceless_starter']!['stripeAmount'];
      final pro =
          CreditSystemService.facelessLtdPlans['faceless_pro']!['stripeAmount'];

      expect(basic, isA<int>());
      expect(starter, isA<int>());
      expect(pro, isA<int>());

      expect(basic, equals(6000));
      expect(starter, equals(9700));
      expect(pro, equals(19700));
    });

    test('Helper methods work correctly', () {
      // Get subscription plan
      final basicPlan = CreditSystemService.getSubscriptionPlan('basic');
      expect(basicPlan, isNotNull);
      expect(basicPlan!['videos'], equals(30));

      // Get credit topup
      final topup10 = CreditSystemService.getCreditTopup('credits_10');
      expect(topup10, isNotNull);
      expect(topup10!['credits'], equals(10));

      // Get Faceless LTD plan
      final facelessBasic = CreditSystemService.getFacelessLtdPlan(
        'faceless_basic',
      );
      expect(facelessBasic, isNotNull);
      expect(facelessBasic!['videos'], equals(30));
    });

    test('Available plans lists return correct data', () {
      final subscriptions = CreditSystemService.getAvailableSubscriptions();
      expect(subscriptions.length, equals(3));
      expect(
        subscriptions.every((plan) => plan['type'] == 'subscription'),
        isTrue,
      );

      final topups = CreditSystemService.getAvailableCreditTopups();
      expect(topups.length, equals(3));
      expect(topups.every((topup) => topup['type'] == 'topup'), isTrue);
    });
  });
}
