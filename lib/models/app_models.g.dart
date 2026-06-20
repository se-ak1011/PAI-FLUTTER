// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      accountType: $enumDecode(_$AccountTypeEnumMap, json['account_type']),
      businessName: json['business_name'] as String?,
      trades:
          (json['trades'] as List<dynamic>).map((e) => e as String).toList(),
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      city: json['city'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool,
      taxRate: (json['tax_rate'] as num).toDouble(),
      subscriptionStatus: json['subscription_status'] as String,
      stripeCustomerId: json['stripe_customer_id'] as String?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'account_type': _$AccountTypeEnumMap[instance.accountType]!,
      'business_name': instance.businessName,
      'trades': instance.trades,
      'hourly_rate': instance.hourlyRate,
      'city': instance.city,
      'onboarding_complete': instance.onboardingComplete,
      'tax_rate': instance.taxRate,
      'subscription_status': instance.subscriptionStatus,
      'stripe_customer_id': instance.stripeCustomerId,
    };

const _$AccountTypeEnumMap = {
  AccountType.contractor: 'contractor',
  AccountType.customer: 'customer',
  AccountType.both: 'both',
};

JobPost _$JobPostFromJson(Map<String, dynamic> json) => JobPost(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      trade: json['trade'] as String?,
      status: json['status'] as String,
      budget: (json['budget'] as num?)?.toDouble(),
      aiScope: json['ai_scope'] as String?,
      aiMaterials: (json['ai_materials'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$JobPostToJson(JobPost instance) => <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'title': instance.title,
      'description': instance.description,
      'trade': instance.trade,
      'status': instance.status,
      'budget': instance.budget,
      'ai_scope': instance.aiScope,
      'ai_materials': instance.aiMaterials,
      'created_at': instance.createdAt?.toIso8601String(),
    };

JobApplication _$JobApplicationFromJson(Map<String, dynamic> json) =>
    JobApplication(
      id: json['id'] as String,
      jobPostId: json['job_post_id'] as String,
      contractorId: json['contractor_id'] as String,
      quoteAmount: (json['quote_amount'] as num).toDouble(),
      message: json['message'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$JobApplicationToJson(JobApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'job_post_id': instance.jobPostId,
      'contractor_id': instance.contractorId,
      'quote_amount': instance.quoteAmount,
      'message': instance.message,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
    };

PrivateJob _$PrivateJobFromJson(Map<String, dynamic> json) => PrivateJob(
      id: json['id'] as String,
      contractorId: json['contractor_id'] as String,
      title: json['title'] as String,
      customer: json['customer'] as String?,
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      labour: (json['labour'] as num).toDouble(),
      materials: (json['materials'] as num).toDouble(),
      vat: (json['vat'] as num).toDouble(),
      jobType: json['job_type'] as String?,
      actualHours: (json['actual_hours'] as num?)?.toDouble(),
      sourceJobPostId: json['source_job_post_id'] as String?,
    );

Map<String, dynamic> _$PrivateJobToJson(PrivateJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contractor_id': instance.contractorId,
      'title': instance.title,
      'customer': instance.customer,
      'status': instance.status,
      'total': instance.total,
      'labour': instance.labour,
      'materials': instance.materials,
      'vat': instance.vat,
      'job_type': instance.jobType,
      'actual_hours': instance.actualHours,
      'source_job_post_id': instance.sourceJobPostId,
    };

ManualIncome _$ManualIncomeFromJson(Map<String, dynamic> json) => ManualIncome(
      id: json['id'] as String,
      contractorId: json['contractor_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      customerName: json['customer_name'] as String?,
      taxRate: (json['tax_rate'] as num).toDouble(),
      taxSetAside: (json['tax_set_aside'] as num).toDouble(),
    );

Map<String, dynamic> _$ManualIncomeToJson(ManualIncome instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contractor_id': instance.contractorId,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'customer_name': instance.customerName,
      'tax_rate': instance.taxRate,
      'tax_set_aside': instance.taxSetAside,
    };

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      subjectId: json['subject_id'] as String,
      jobPostId: json['job_post_id'] as String?,
      mode: json['mode'] as String,
      rating: (json['rating'] as num).toInt(),
      categories: json['categories'] as Map<String, dynamic>,
      status: json['status'] as String,
    );

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'subject_id': instance.subjectId,
      'job_post_id': instance.jobPostId,
      'mode': instance.mode,
      'rating': instance.rating,
      'categories': instance.categories,
      'status': instance.status,
    };

Dispute _$DisputeFromJson(Map<String, dynamic> json) => Dispute(
      id: json['id'] as String,
      jobPostId: json['job_post_id'] as String?,
      contractorId: json['contractor_id'] as String,
      customerId: json['customer_id'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      resolutionNote: json['resolution_note'] as String?,
    );

Map<String, dynamic> _$DisputeToJson(Dispute instance) => <String, dynamic>{
      'id': instance.id,
      'job_post_id': instance.jobPostId,
      'contractor_id': instance.contractorId,
      'customer_id': instance.customerId,
      'reason': instance.reason,
      'status': instance.status,
      'resolution_note': instance.resolutionNote,
    };
