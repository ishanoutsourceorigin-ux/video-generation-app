"use client";

import Link from "next/link";
import {
  ArrowLeft,
  Shield,
  Eye,
  Database,
  Lock,
  Mail,
  Phone,
} from "lucide-react";

export default function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <div className="max-w-4xl mx-auto px-6 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mx-auto mb-6">
            <Shield className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-4xl font-bold text-white mb-4">Privacy Policy</h1>
          <p className="text-gray-300 text-lg">
            CloneX - AI Video Generation Platform
          </p>
          <p className="text-gray-400 text-sm mt-2">
            Last updated: October 17, 2025
          </p>
        </div>

        {/* Content */}
        <div className="glass-effect rounded-2xl p-8 lg:p-12">
          <div className="prose prose-invert prose-purple max-w-none">
            {/* Introduction */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <Eye className="w-6 h-6 mr-2 text-purple-400" />
                Introduction
              </h2>
              <p className="text-gray-300 leading-relaxed">
                Welcome to CloneX (we, our, or us). We are committed to
                protecting your privacy and ensuring the security of your
                personal information. This Privacy Policy explains how we
                collect, use, disclose, and safeguard your information when you
                use our AI video generation platform and mobile application.
              </p>
              <p className="text-gray-300 leading-relaxed mt-4">
                By using CloneX, you agree to the collection and use of
                information in accordance with this policy. If you do not agree
                with our policies and practices, please do not use our services.
              </p>
            </section>

            {/* Information We Collect */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <Database className="w-6 h-6 mr-2 text-purple-400" />
                Information We Collect
              </h2>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Personal Information
              </h3>
              <p className="text-gray-300 mb-3">
                We collect the following types of personal information:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>
                  • <strong>Account Information:</strong> Email address,
                  username, and password
                </li>
                <li>
                  • <strong>Profile Data:</strong> Display name, profile
                  picture, and user preferences
                </li>
                <li>
                  • <strong>Payment Information:</strong> Billing details for
                  credit purchases (processed securely through third-party
                  payment providers)
                </li>
                <li>
                  • <strong>Contact Information:</strong> When you reach out to
                  our support team
                </li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Usage Data
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Video generation requests and preferences</li>
                <li>• Avatar creation data and images you upload</li>
                <li>• App usage analytics and performance metrics</li>
                <li>
                  • Device information (model, operating system, unique device
                  identifiers)
                </li>
                <li>• IP address and location data (approximate)</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Content Data
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Text prompts for video generation</li>
                <li>• Images uploaded for avatar creation</li>
                <li>• Generated videos and content</li>
                <li>• User-created projects and history</li>
              </ul>
            </section>

            {/* How We Use Your Information */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <Lock className="w-6 h-6 mr-2 text-purple-400" />
                How We Use Your Information
              </h2>
              <p className="text-gray-300 mb-3">
                We use your information for the following purposes:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>
                  • <strong>Service Provision:</strong> To provide and maintain
                  our AI video generation services
                </li>
                <li>
                  • <strong>Account Management:</strong> To create and manage
                  your user account
                </li>
                <li>
                  • <strong>Payment Processing:</strong> To process credit
                  purchases and manage billing
                </li>
                <li>
                  • <strong>Content Generation:</strong> To process your
                  requests and generate AI videos and avatars
                </li>
                <li>
                  • <strong>Communication:</strong> To send you service updates,
                  support responses, and important notices
                </li>
                <li>
                  • <strong>Improvement:</strong> To analyze usage patterns and
                  improve our services
                </li>
                <li>
                  • <strong>Security:</strong> To detect and prevent fraud,
                  abuse, and security incidents
                </li>
                <li>
                  • <strong>Legal Compliance:</strong> To comply with applicable
                  laws and regulations
                </li>
              </ul>
            </section>

            {/* Information Sharing */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Information Sharing and Disclosure
              </h2>
              <p className="text-gray-300 mb-3">
                We do not sell, trade, or rent your personal information. We may
                share information in the following circumstances:
              </p>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Service Providers
              </h3>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Cloud hosting and data storage providers</li>
                <li>• Payment processing companies</li>
                <li>• AI processing and machine learning services</li>
                <li>• Analytics and performance monitoring tools</li>
                <li>• Customer support platforms</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Legal Requirements
              </h3>
              <p className="text-gray-300">
                We may disclose your information if required by law or in
                response to valid legal requests from authorities.
              </p>

              <h3 className="text-xl font-semibold text-white mb-3 mt-6">
                Business Transfers
              </h3>
              <p className="text-gray-300">
                In the event of a merger, acquisition, or asset sale, your
                information may be transferred as part of that transaction.
              </p>
            </section>

            {/* Data Security */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Data Security
              </h2>
              <p className="text-gray-300 mb-3">
                We implement industry-standard security measures to protect your
                information:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>• Encryption of data in transit and at rest</li>
                <li>• Secure authentication and access controls</li>
                <li>• Regular security audits and updates</li>
                <li>
                  • Limited access to personal information on a need-to-know
                  basis
                </li>
                <li>
                  • Secure payment processing through PCI-compliant providers
                </li>
              </ul>
              <p className="text-gray-300 mt-4">
                However, no method of transmission over the internet or
                electronic storage is 100% secure. While we strive to protect
                your information, we cannot guarantee absolute security.
              </p>
            </section>

            {/* Data Retention */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Data Retention
              </h2>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>
                  • <strong>Account Data:</strong> Retained while your account
                  is active and for a reasonable period after deletion
                </li>
                <li>
                  • <strong>Generated Content:</strong> Stored according to your
                  account settings and service requirements
                </li>
                <li>
                  • <strong>Payment Data:</strong> Retained as required for tax
                  and accounting purposes
                </li>
                <li>
                  • <strong>Usage Analytics:</strong> Aggregated data may be
                  retained indefinitely for service improvement
                </li>
              </ul>
            </section>

            {/* Your Rights */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Your Privacy Rights
              </h2>
              <p className="text-gray-300 mb-3">
                Depending on your location, you may have the following rights:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>
                  • <strong>Access:</strong> Request access to your personal
                  information
                </li>
                <li>
                  • <strong>Correction:</strong> Request correction of
                  inaccurate information
                </li>
                <li>
                  • <strong>Deletion:</strong> Request deletion of your personal
                  information
                </li>
                <li>
                  • <strong>Portability:</strong> Request a copy of your data in
                  a portable format
                </li>
                <li>
                  • <strong>Restriction:</strong> Request limitation of
                  processing of your information
                </li>
                <li>
                  • <strong>Objection:</strong> Object to certain types of
                  processing
                </li>
                <li>
                  • <strong>Withdraw Consent:</strong> Withdraw previously given
                  consent
                </li>
              </ul>
              <p className="text-gray-300 mt-4">
                To exercise these rights, please contact us using the
                information provided below.
              </p>
            </section>

            {/* Children's Privacy */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Children&apos;s Privacy
              </h2>
              <p className="text-gray-300">
                CloneX is not intended for use by children under the age of 13.
                We do not knowingly collect personal information from children
                under 13. If we become aware that we have collected personal
                information from a child under 13, we will take steps to delete
                such information promptly.
              </p>
            </section>

            {/* International Data Transfers */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                International Data Transfers
              </h2>
              <p className="text-gray-300">
                Your information may be transferred to and processed in
                countries other than your own. We ensure appropriate safeguards
                are in place to protect your information during such transfers,
                including standard contractual clauses and adequacy decisions.
              </p>
            </section>

            {/* Third-Party Services */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Third-Party Services
              </h2>
              <p className="text-gray-300 mb-3">
                Our app may contain links to third-party services or integrate
                with external platforms:
              </p>
              <ul className="text-gray-300 space-y-2 ml-6">
                <li>
                  • Firebase (Google) - Authentication and database services
                </li>
                <li>• Cloudinary - Media storage and processing</li>
                <li>• Payment processors - Secure payment handling</li>
                <li>• Analytics services - Usage and performance tracking</li>
              </ul>
              <p className="text-gray-300 mt-4">
                These services have their own privacy policies, and we encourage
                you to review them.
              </p>
            </section>

            {/* Changes to Privacy Policy */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4">
                Changes to This Privacy Policy
              </h2>
              <p className="text-gray-300">
                We may update this Privacy Policy from time to time. We will
                notify you of any changes by posting the new Privacy Policy on
                this page and updating the Last updated date. We encourage you
                to review this Privacy Policy periodically for any changes.
              </p>
            </section>

            {/* Contact Information */}
            <section className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-4 flex items-center">
                <Mail className="w-6 h-6 mr-2 text-purple-400" />
                Contact Us
              </h2>
              <p className="text-gray-300 mb-4">
                If you have any questions about this Privacy Policy or our data
                practices, please contact us:
              </p>
              <div className="bg-white/5 border border-white/10 rounded-lg p-6">
                <div className="space-y-3">
                  <div className="flex items-center text-gray-300">
                    <Mail className="w-5 h-5 mr-3 text-purple-400" />
                    <span>Email: support@clonex.app</span>
                  </div>
                  <div className="flex items-center text-gray-300">
                    <Phone className="w-5 h-5 mr-3 text-purple-400" />
                    <span>Phone: +1 (555) 123-4567</span>
                  </div>
                  <div className="flex items-start text-gray-300">
                    <Shield className="w-5 h-5 mr-3 text-purple-400 mt-0.5" />
                    <div>
                      <p>Data Protection Officer</p>
                      <p className="text-sm text-gray-400">
                        privacy@clonex.app
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </div>

        {/* Back to Login */}
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
