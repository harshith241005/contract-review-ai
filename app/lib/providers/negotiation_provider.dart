// Negotiation Provider - Enhanced state management for negotiation assistant

import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../models/negotiation.dart';
import '../models/sla_data.dart';
import '../services/api_service.dart';

class NegotiationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Chat messages
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;
  
  // Negotiation points
  List<NegotiationPoint> _negotiationPoints = [];
  List<NegotiationPoint> get negotiationPoints => _negotiationPoints;
  
  // Backend negotiation points
  List<String> _backendPoints = [];
  List<String> get backendPoints => _backendPoints;
  
  // Loading state
  bool _isTyping = false;
  bool get isTyping => _isTyping;
  
  // Current contract context
  Contract? _currentContract;
  
  // Quick action usage tracking
  final Map<String, int> _quickActionUsage = {};
  
  // Initialize with welcome message
  void initialize(Contract? contract) {
    _currentContract = contract;
    _messages = [
      ChatMessage.assistant(
        "Hi! I reviewed your contract and I am ready to help.\n\n"
        "Pick a quick action above or ask one focused question.\n"
        "Examples: lower APR strategy, dealer email draft, or key questions to ask."
      ),
    ];
    
    // Generate negotiation points from contract
    if (contract?.slaData != null) {
      _generateNegotiationPoints(contract!.slaData!);
      _fetchBackendNegotiationPoints(contract);
    }
    
    notifyListeners();
  }
  
  // Fetch negotiation points from backend
  Future<void> _fetchBackendNegotiationPoints(Contract contract) async {
    if (contract.slaData == null) return;
    
    try {
      final response = await _apiService.getNegotiationPoints(
        contract.slaData!,
        contract.fairnessScore?.toJson(),
      );
      
      if (response.isSuccess && response.data != null) {
        _backendPoints = response.data!;
        
        for (var point in _backendPoints) {
          _negotiationPoints.add(NegotiationPoint(
            title: 'Recommendation',
            description: point,
            priority: NegotiationPriority.medium,
            category: 'recommendation',
          ));
        }
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - we have local points as fallback
    }
  }
  
  // Track quick action usage
  void trackQuickAction(String action) {
    _quickActionUsage[action] = (_quickActionUsage[action] ?? 0) + 1;
  }
  
  // Send a message
  Future<void> sendMessage(String content) async {
    // Add user message
    _messages.add(ChatMessage.user(content));
    notifyListeners();
    
    // Simulate AI typing
    _isTyping = true;
    notifyListeners();
    
    // Simulate AI typing minimum delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Generate response based on content
    final response = await _generateResponse(content);
    _messages.add(ChatMessage.assistant(response));
    
    _isTyping = false;
    notifyListeners();
  }
  
  // Generate negotiation points from SLA
  void _generateNegotiationPoints(SlaData sla) {
    _negotiationPoints.clear();
    
    // Check APR
    final apr = double.tryParse(sla.interestRateApr ?? '');
    if (apr != null && apr > 8) {
      _negotiationPoints.add(NegotiationPoint(
        title: 'High Interest Rate',
        description: 'Your APR of ${apr}% is above average. Current market rates are around 5-7% for good credit.',
        priority: NegotiationPriority.high,
        suggestedAction: 'Ask for rate reduction or shop around with other lenders.',
        category: 'financing',
      ));
    }
    
    // Check early termination
    if (sla.earlyTerminationClause != null && 
        !sla.earlyTerminationClause!.toLowerCase().contains('no penalty')) {
      _negotiationPoints.add(NegotiationPoint(
        title: 'Early Termination Penalty',
        description: 'Contract includes early termination fees. This limits your flexibility.',
        priority: NegotiationPriority.medium,
        suggestedAction: 'Negotiate a lower penalty or grace period for early payoff.',
        category: 'terms',
      ));
    }
    
    // Check mileage limits for leases
    final mileage = int.tryParse(sla.mileageAllowance?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
    if (mileage != null && mileage < 12000) {
      _negotiationPoints.add(NegotiationPoint(
        title: 'Low Mileage Allowance',
        description: 'Annual mileage of $mileage miles may be insufficient for average drivers.',
        priority: NegotiationPriority.medium,
        suggestedAction: 'Request higher mileage limit or negotiate lower overage charges.',
        category: 'terms',
      ));
    }
    
    // Check red flags
    for (var flag in sla.redFlags) {
      _negotiationPoints.add(NegotiationPoint(
        title: 'Red Flag Detected',
        description: flag,
        priority: NegotiationPriority.high,
        category: 'risk',
      ));
    }
    
    notifyListeners();
  }
  
  // Generate AI response
  Future<String> _generateResponse(String userMessage) async {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('interest') || lowerMessage.contains('apr') || lowerMessage.contains('rate')) {
      return _getInterestAdvice();
    }
    
    if (lowerMessage.contains('email') || lowerMessage.contains('write') || lowerMessage.contains('message') || lowerMessage.contains('draft')) {
      return await _generateLiveEmailDraft();
    }
    
    if (lowerMessage.contains('question') || lowerMessage.contains('ask')) {
      return await _getLiveSuggestedQuestions();
    }
    
    if (lowerMessage.contains('negotiate') || lowerMessage.contains('deal') || lowerMessage.contains('better') || lowerMessage.contains('tip')) {
      return _getNegotiationTips();
    }
    
    if (lowerMessage.contains('mileage') || lowerMessage.contains('miles')) {
      return _getMileageAdvice();
    }
    
    if (lowerMessage.contains('down payment') || lowerMessage.contains('downpayment')) {
      return _getDownPaymentAdvice();
    }
    
    if (lowerMessage.contains('refinanc')) {
      return _getRefinancingAdvice();
    }
    
    if (lowerMessage.contains('warranty') || lowerMessage.contains('extended')) {
      return _getWarrantyAdvice();
    }
    
    if (lowerMessage.contains('insurance') || lowerMessage.contains('gap')) {
      return _getInsuranceAdvice();
    }
    
    // Default response
    if (_currentContract != null && _currentContract!.slaData != null) {
      try {
        final chatResponse = await _apiService.chatWithAssistant(
          message: userMessage,
          sla: _currentContract!.slaData!.toJson(),
        );
        if (chatResponse.isSuccess && chatResponse.data != null) {
          return chatResponse.data!;
        } else {
          return "API call returned false success. Error: ${chatResponse.error}";
        }
      } catch (e) {
        return "An error occurred while reaching the local AI: $e";
      }
    }
    
    return "I understand you're looking for help with your car loan. Here are some things I can assist with:\n\n"
        "📝 **Contract Analysis** — Ask me about specific terms\n"
        "💰 **Rate Negotiation** — Tips to get better rates\n"
        "✉️ **Email Drafts** — I can write emails to dealers\n"
        "❓ **Questions to Ask** — Important questions for dealers\n"
        "🔄 **Refinancing** — When and how to refinance\n"
        "🛡️ **Warranty & Insurance** — Coverage advice\n\n"
        "What would you like me to help you with?";
  }
  
  String _getInterestAdvice() {
    final apr = _currentContract?.slaData?.interestRateApr;
    return "📊 **Interest Rate Analysis**\n\n"
        "${apr != null ? 'Your current APR: **$apr%**\n\n' : ''}"
        "**Tips for negotiating a better rate:**\n\n"
        "1️⃣ Check your credit score before negotiating\n"
        "2️⃣ Get pre-approved from banks/credit unions first\n"
        "3️⃣ Use competing offers as leverage\n"
        "4️⃣ Ask about special promotions or loyalty discounts\n"
        "5️⃣ Consider a shorter loan term for lower rates\n\n"
        "**Market Rate Reference:**\n"
        "• Excellent credit (720+): 4.5% - 6.0%\n"
        "• Good credit (680-719): 6.0% - 8.0%\n"
        "• Fair credit (620-679): 8.0% - 12.0%\n\n"
        "Would you like me to draft an email to request a rate reduction?";
  }
  
  Future<String> _generateLiveEmailDraft() async {
    if (_currentContract == null || _currentContract!.slaData == null) {
      return "I need you to upload a contract first before I can write an accurate, personalized email draft!";
    }
    
    try {
      final response = await _apiService.generateNegotiationEmail(
        sla: _currentContract!.slaData!.toJson(),
        points: _backendPoints.isEmpty ? ['Requesting a lower APR matching market conditions', 'Waiving unnecessary dealer documentation fees'] : _backendPoints,
      );
      
      if (response.isSuccess && response.data != null) {
        return "✉️ **Draft Email to Dealer**\n\n---\n${response.data}\n\n---\n💡 **Pro Tip:** Attach any pre-approval letters to show you are serious!";
      }
      return "Sorry, there was an issue connecting to the AI backend. Falling back to template:\n\n${_generateEmailDraft()}";
    } catch (e) {
      return _generateEmailDraft();
    }
  }

  Future<String> _getLiveSuggestedQuestions() async {
    try {
      final response = await _apiService.getDealerQuestions();
      
      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        String md = "❓ **Here are smart questions to ask your dealer right now:**\n\n";
        for (var q in response.data!) {
          md += "• $q\n";
        }
        return md;
      }
      return _getSuggestedQuestions();
    } catch (e) {
      return _getSuggestedQuestions();
    }
  }

  String _generateEmailDraft() {
    return "✉️ **Template Email to Dealer**\n\n"
        "---\n"
        "Subject: Request for Rate Review - Loan Application\n\n"
        "Dear [Dealer/Finance Manager],\n\n"
        "Thank you for the loan offer for [Vehicle]. After reviewing the terms, "
        "I would like to discuss the interest rate.\n\n"
        "I have been pre-approved by [Bank Name] at a lower rate of [X]%, "
        "and I would appreciate if you could match or improve upon this offer.\n\n"
        "I am a serious buyer and ready to finalize the deal if we can agree on better terms.\n\n"
        "Please let me know your thoughts.\n\n"
        "Best regards,\n"
        "[Your Name]\n"
        "[Phone Number]\n"
        "---\n\n"
        "💡 **Pro Tip:** Attach your pre-approval letter for maximum leverage!";
  }
  
  String _getSuggestedQuestions() {
    return "❓ **Questions to Ask the Dealer:**\n\n"
        "**About Pricing:**\n"
        "• What is the out-the-door price including all fees?\n"
        "• Are there any dealer add-ons I can remove?\n"
        "• Is there room for negotiation on the price?\n\n"
        "**About Financing:**\n"
        "• What APR am I approved for?\n"
        "• Can you match a rate from my bank/credit union?\n"
        "• Are there any financing promotions available?\n\n"
        "**About the Loan:**\n"
        "• Is there a prepayment penalty?\n"
        "• Can I pay extra towards principal?\n"
        "• What happens if I want to refinance later?\n\n"
        "**Hidden Fees to Watch:**\n"
        "• Documentation fees\n"
        "• Dealer preparation charges\n"
        "• VIN etching fees\n\n"
        "Would you like more questions about any specific topic?";
  }
  
  String _getNegotiationTips() {
    return "💪 **Negotiation Tips:**\n\n"
        "**Before Going to Dealer:**\n"
        "✅ Research fair market value (KBB, Edmunds)\n"
        "✅ Get pre-approved financing\n"
        "✅ Check for manufacturer incentives\n"
        "✅ Know your trade-in value\n\n"
        "**At the Dealer:**\n"
        "✅ Negotiate price before discussing financing\n"
        "✅ Don't reveal your monthly payment target\n"
        "✅ Be prepared to walk away\n"
        "✅ Ask for itemized breakdown of all fees\n\n"
        "**Power Moves:**\n"
        "🎯 Shop at end of month/quarter\n"
        "🎯 Get quotes from multiple dealers\n"
        "🎯 Mention competing offers\n"
        "🎯 Ask for dealer holdback discount\n\n"
        "Want me to analyze your specific contract for negotiation opportunities?";
  }
  
  String _getMileageAdvice() {
    return "🚗 **Mileage Allowance Tips:**\n\n"
        "The average American drives 12,000-15,000 miles per year.\n\n"
        "**If your allowance is too low:**\n"
        "• Negotiate higher mileage upfront (cheaper than overage)\n"
        "• Ask about mileage rollover options\n"
        "• Request lower per-mile overage charges\n\n"
        "**Overage Charges:**\n"
        "Typical range: \$0.15 - \$0.30 per mile\n"
        "Negotiate to the lower end if possible.\n\n"
        "Would you like to calculate potential overage costs?";
  }
  
  String _getDownPaymentAdvice() {
    return "💵 **Down Payment Strategy:**\n\n"
        "**For Loans:**\n"
        "• 20% down is ideal to avoid negative equity\n"
        "• Larger down payment = lower monthly payments\n"
        "• Some lenders offer better rates with more down\n\n"
        "**For Leases:**\n"
        "• Consider minimal down payment\n"
        "• If car is totaled, you lose your down payment\n"
        "• Multiple Security Deposits (MSD) may lower rate\n\n"
        "**Negotiation Tip:**\n"
        "Don't discuss down payment until price is settled!\n\n"
        "What's your current down payment situation?";
  }
  
  String _getRefinancingAdvice() {
    return "🔄 **Refinancing Your Auto Loan:**\n\n"
        "**When to Refinance:**\n"
        "• Your credit score has improved significantly\n"
        "• Market interest rates have dropped\n"
        "• You're paying above-average rates\n"
        "• You want to change loan duration\n\n"
        "**How to Refinance:**\n"
        "1️⃣ Check your current loan balance and rate\n"
        "2️⃣ Compare offers from banks & credit unions\n"
        "3️⃣ Calculate total savings after fees\n"
        "4️⃣ Apply with the best lender\n"
        "5️⃣ Complete the transfer process\n\n"
        "**Watch Out For:**\n"
        "• Prepayment penalties on current loan\n"
        "• Extending loan term (reduces monthly but costs more)\n"
        "• Application fees from new lender\n\n"
        "Would you like help comparing refinancing options?";
  }
  
  String _getWarrantyAdvice() {
    return "🛡️ **Extended Warranty Guide:**\n\n"
        "**Before Buying Extended Warranty:**\n"
        "• Check what factory warranty still covers\n"
        "• Compare dealership vs third-party warranties\n"
        "• Read exclusions carefully\n\n"
        "**What's Usually Worth It:**\n"
        "✅ Powertrain coverage for high-mileage vehicles\n"
        "✅ Comprehensive plans for luxury/complex cars\n"
        "✅ Coverage from reputable providers\n\n"
        "**Usually Not Worth It:**\n"
        "• Short-term plans on reliable new cars\n"
        "• Dealer markups on third-party warranties\n"
        "• Plans with high deductibles\n\n"
        "**Negotiation Tip:**\n"
        "Extended warranties have huge markups — always negotiate the price down by 30-50%!\n\n"
        "Need help evaluating a specific warranty offer?";
  }
  
  String _getInsuranceAdvice() {
    return "🏦 **Auto Insurance & GAP Coverage:**\n\n"
        "**GAP Insurance:**\n"
        "• Covers difference between car value and loan balance\n"
        "• Essential if down payment < 20%\n"
        "• Buy from insurer, NOT dealer (saves 50%+)\n\n"
        "**Money-Saving Tips:**\n"
        "✅ Bundle with home/renter's insurance\n"
        "✅ Increase deductible to lower premium\n"
        "✅ Ask about safe driver discounts\n"
        "✅ Compare quotes from 3+ companies\n"
        "✅ Review coverage annually\n\n"
        "**Coverage You Need:**\n"
        "• Liability (required by law)\n"
        "• Collision (for financed vehicles)\n"
        "• Comprehensive (theft, weather, etc.)\n"
        "• Uninsured motorist protection\n\n"
        "Would you like tips on reducing your premium?";
  }
  
  // Clear chat
  void clearChat() {
    _messages.clear();
    initialize(_currentContract);
  }
}
