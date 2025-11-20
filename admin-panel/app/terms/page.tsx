"use client";

/* eslint-disable react/no-unescaped-entities */

import Link from "next/link";
import {
  ArrowLeft,
  FileText,
  Shield,
  AlertTriangle,
  CreditCard,
  Users,
  Scale,
} from "lucide-react";

export default function TermsOfUsePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <div className="max-w-4xl mx-auto px-6 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mx-auto mb-6">
            <FileText className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-4xl font-bold text-white mb-4">Terms of Use</h1>
          <p className="text-gray-300 text-lg">
            CloneX - AI Video Generation Platform
          </p>
          <p className="text-gray-400 text-sm mt-2">
            Last updated: November 21, 2025
          </p>
        </div>

        {/* Content */}
        <div className="glass-effect rounded-2xl p-8 lg:p-12">
          <div className="prose prose-invert prose-purple max-w-none">
            
            {/* Acceptance of Terms */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <Scale className="w-6 h-6 mr-2 text-purple-400" />
                Acceptance of Terms
              </h2>
              <p className="text-gray-300 leading-relaxed">
                Welcome to CloneX! By downloading, installing, or using our mobile application and services, 
                you agree to be bound by these Terms of Use (&quot;Terms&quot;). If you do not agree to these Terms, 
                please do not use our services.
              </p>
              <p className="text-gray-300 leading-relaxed mt-4">
                These Terms constitute a legally binding agreement between you and CloneX. We may modify 
                these Terms at any time, and such modifications will be effective immediately upon posting. 
                Your continued use of the service following any changes indicates your acceptance of the new Terms.
              </p>
            </section>

            {/* Description of Service */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <Users className="w-6 h-6 mr-2 text-purple-400" />
                Description of Service
              </h2>
              <p className="text-gray-300 mb-3">
                CloneX is an AI-powered video generation platform that allows users to:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Create AI avatars from uploaded photos</li>
                <li>• Generate videos with AI avatars speaking custom text</li>
                <li>• Create text-to-video content using AI technology</li>
                <li>• Manage and download generated video content</li>
                <li>• Purchase credits and subscription plans for video generation</li>
              </ul>
              <p className="text-gray-300 mt-4">
                Our service uses artificial intelligence and machine learning technologies to process 
                your content and generate videos. The quality and accuracy of generated content may vary.
              </p>
            </section>

            {/* User Accounts and Registration */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                User Accounts and Registration
              </h2>
              <p className="text-gray-300 mb-3">
                To use CloneX, you must create an account and provide accurate information:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• You must be at least 13 years old to create an account</li>
                <li>• You are responsible for maintaining the security of your account</li>
                <li>• You must provide accurate and complete registration information</li>
                <li>• You are responsible for all activities that occur under your account</li>
                <li>• You must immediately notify us of any unauthorized use of your account</li>
              </ul>
            </section>

            {/* Acceptable Use Policy */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <Shield className="w-6 h-6 mr-2 text-purple-400" />
                Acceptable Use Policy
              </h2>
              <p className="text-gray-300 mb-3">
                You agree NOT to use CloneX for:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Creating content that impersonates others without consent</li>
                <li>• Generating misleading, deceptive, or false content</li>
                <li>• Creating content that violates any applicable laws or regulations</li>
                <li>• Harassment, bullying, or threatening content</li>
                <li>• Adult, sexual, or pornographic content</li>
                <li>• Content that promotes violence, hatred, or discrimination</li>
                <li>• Infringing on intellectual property rights of others</li>
                <li>• Spreading misinformation or conspiracy theories</li>
                <li>• Any illegal, harmful, or unethical purposes</li>
              </ul>

              <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4 mt-6">
                <div className="flex items-start">
                  <AlertTriangle className="w-5 h-5 text-red-400 mr-3 mt-0.5" />
                  <div>
                    <h3 className="text-red-400 font-semibold mb-2">Important Notice</h3>
                    <p className="text-gray-300 text-sm">
                      CloneX is designed for legitimate creative and educational purposes. 
                      Users must obtain proper consent before creating avatars of other people. 
                      Any misuse of our platform may result in immediate account termination.
                    </p>
                  </div>
                </div>
              </div>
            </section>

            {/* Payment Terms and Subscriptions */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <CreditCard className="w-6 h-6 mr-2 text-purple-400" />
                Payment Terms and Subscriptions
              </h2>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Auto-Renewable Subscriptions
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• <strong>Basic Plan:</strong> $2.7/month - 30 videos per month</li>
                <li>• <strong>Starter Plan:</strong> $4.7/month - 60 videos per month</li>
                <li>• <strong>Pro Plan:</strong> $9.7/month - 150 videos per month</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Subscription Terms
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Subscriptions automatically renew monthly unless cancelled</li>
                <li>• Payment is charged to your Apple ID account at confirmation of purchase</li>
                <li>• Account will be charged for renewal within 24 hours prior to the end of the current period</li>
                <li>• Auto-renewal may be turned off in your Apple ID Account Settings</li>
                <li>• No cancellation of the current subscription is allowed during active subscription period</li>
                <li>• Unused credits from monthly allowance do not roll over to the next month</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Credit Top-ups
              </h3>
              <p className="text-gray-300 mb-3">
                In addition to subscriptions, you may purchase credit top-ups:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Credit top-ups are one-time purchases</li>
                <li>• Credits do not expire</li>
                <li>• Credits can be used alongside active subscriptions</li>
                <li>• All sales are final - no refunds on credit purchases</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Refund Policy
              </h3>
              <p className="text-gray-300">
                All purchases are subject to Apple&apos;s refund policies. For subscription cancellations 
                and refunds, please contact Apple Support directly through your device settings or 
                the App Store.
              </p>
            </section>

            {/* Content and Intellectual Property */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Content and Intellectual Property
              </h2>
              
              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Your Content
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• You retain ownership of content you upload (images, text, etc.)</li>
                <li>• You grant CloneX a license to process your content for service provision</li>
                <li>• You are responsible for ensuring you have rights to all content you upload</li>
                <li>• You warrant that your content does not infringe on third-party rights</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Generated Content
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• You own the videos and avatars generated using our platform</li>
                <li>• CloneX retains the right to use anonymized data for service improvement</li>
                <li>• You may use generated content for personal and commercial purposes</li>
                <li>• You are responsible for how you use and distribute generated content</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                CloneX Platform
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• CloneX owns all rights to the platform, software, and technology</li>
                <li>• Our trademarks, logos, and brand elements are our property</li>
                <li>• You may not copy, modify, or reverse engineer our platform</li>
              </ul>
            </section>

            {/* Privacy and Data Protection */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Privacy and Data Protection
              </h2>
              <p className="text-gray-300 mb-3">
                Your privacy is important to us. Our data collection and usage practices are 
                described in detail in our Privacy Policy, which is incorporated by reference 
                into these Terms.
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• We collect and process data as described in our Privacy Policy</li>
                <li>• We implement security measures to protect your information</li>
                <li>• We do not sell your personal data to third parties</li>
                <li>• You can request deletion of your data at any time</li>
              </ul>
            </section>

            {/* Disclaimers and Limitations */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Disclaimers and Limitations
              </h2>
              
              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Service Availability
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• CloneX is provided &quot;as is&quot; without warranties of any kind</li>
                <li>• We do not guarantee uninterrupted or error-free service</li>
                <li>• Service availability may vary due to maintenance or technical issues</li>
                <li>• AI-generated content quality may vary and is not guaranteed</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Limitation of Liability
              </h3>
              <p className="text-gray-300">
                To the maximum extent permitted by law, CloneX shall not be liable for any 
                indirect, incidental, special, consequential, or punitive damages, including 
                but not limited to loss of profits, data, or use, incurred by you or any third party.
              </p>
            </section>

            {/* Account Termination */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Account Termination
              </h2>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• You may delete your account at any time through the app settings</li>
                <li>• We may terminate accounts that violate these Terms</li>
                <li>• Upon termination, your access to the service will be discontinued</li>
                <li>• Some data may be retained as required by law or for legitimate business purposes</li>
                <li>• Active subscriptions will continue until the end of the billing period</li>
              </ul>
            </section>

            {/* Governing Law */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Governing Law and Disputes
              </h2>
              <p className="text-gray-300 mb-3">
                These Terms shall be governed by and construed in accordance with the laws 
                of [Your Jurisdiction]. Any disputes arising from these Terms or your use 
                of CloneX shall be resolved through binding arbitration.
              </p>
              <p className="text-gray-300">
                For any questions regarding these Terms, please contact us at: legal@clonex.app
              </p>
            </section>

            {/* Contact Information */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Contact Information
              </h2>
              <p className="text-gray-300 mb-4">
                For questions about these Terms of Use, please contact us:
              </p>
              <div className="bg-white/5 border border-white/10 rounded-lg p-6">
                <div className="space-y-3">
                  <div className="flex items-center text-gray-300">
                    <FileText className="w-5 h-5 mr-3 text-purple-400" />
                    <span>Email: legal@clonex.app</span>
                  </div>
                  <div className="flex items-center text-gray-300">
                    <Users className="w-5 h-5 mr-3 text-purple-400" />
                    <span>Support: support@clonex.app</span>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </div>

        {/* Back to Admin */}
        <div className="text-center mt-8">
          <Link
            href="/admin"
            className="inline-flex items-center text-gray-400 hover:text-white transition-colors"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Admin Login
          </Link>
        </div>
      </div>
    </div>
  );
}
