import 'package:json_annotation/json_annotation.dart';

part 'app_models.g.dart';

enum AccountType { contractor, customer, both }

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class UserProfile {
  final String id;
  final String? email;
  final String? username;
  final AccountType accountType;
  final String? businessName;
  final List<String> trades;
  final double? hourlyRate;
  final String? city;
  final bool onboardingComplete;
  final double taxRate;
  final String subscriptionStatus;
  final String? stripeCustomerId;

  UserProfile({
    required this.id,
    this.email,
    this.username,
    required this.accountType,
    this.businessName,
    required this.trades,
    this.hourlyRate,
    this.city,
    required this.onboardingComplete,
    required this.taxRate,
    required this.subscriptionStatus,
    this.stripeCustomerId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class JobPost {
  final String id;
  final String clientId;
  final String title;
  final String? description;
  final String? trade;
  final String status;
  final double? budget;
  final String? aiScope;
  final List<String>? aiMaterials;
  final DateTime? createdAt;

  JobPost({
    required this.id,
    required this.clientId,
    required this.title,
    this.description,
    this.trade,
    required this.status,
    this.budget,
    this.aiScope,
    this.aiMaterials,
    this.createdAt,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) => _$JobPostFromJson(json);
  Map<String, dynamic> toJson() => _$JobPostToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class JobApplication {
  final String id;
  final String jobPostId;
  final String contractorId;
  final double quoteAmount;
  final String? message;
  final String status;
  final DateTime? createdAt;

  JobApplication({
    required this.id,
    required this.jobPostId,
    required this.contractorId,
    required this.quoteAmount,
    this.message,
    required this.status,
    this.createdAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) => _$JobApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$JobApplicationToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class PrivateJob {
  final String id;
  final String contractorId;
  final String title;
  final String? customer;
  final String status;
  final double total;
  final double labour;
  final double materials;
  final double vat;
  final String? jobType; // 'fixed' or 'hourly'
  final double? actualHours;
  final String? sourceJobPostId;

  PrivateJob({
    required this.id,
    required this.contractorId,
    required this.title,
    this.customer,
    required this.status,
    required this.total,
    required this.labour,
    required this.materials,
    required this.vat,
    this.jobType,
    this.actualHours,
    this.sourceJobPostId,
  });

  factory PrivateJob.fromJson(Map<String, dynamic> json) => _$PrivateJobFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateJobToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class ManualIncome {
  final String id;
  final String contractorId;
  final double amount;
  final DateTime date;
  final String? customerName;
  final double taxRate;
  final double taxSetAside;

  ManualIncome({
    required this.id,
    required this.contractorId,
    required this.amount,
    required this.date,
    this.customerName,
    required this.taxRate,
    required this.taxSetAside,
  });

  factory ManualIncome.fromJson(Map<String, dynamic> json) => _$ManualIncomeFromJson(json);
  Map<String, dynamic> toJson() => _$ManualIncomeToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Review {
  final String id;
  final String authorId;
  final String subjectId;
  final String? jobPostId;
  final String mode; // 'contractor_to_customer' or 'customer_to_contractor'
  final int rating;
  final Map<String, dynamic> categories;
  final String status;

  Review({
    required this.id,
    required this.authorId,
    required this.subjectId,
    this.jobPostId,
    required this.mode,
    required this.rating,
    required this.categories,
    required this.status,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Dispute {
  final String id;
  final String? jobPostId;
  final String contractorId;
  final String customerId;
  final String reason;
  final String status;
  final String? resolutionNote;

  Dispute({
    required this.id,
    this.jobPostId,
    required this.contractorId,
    required this.customerId,
    required this.reason,
    required this.status,
    this.resolutionNote,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) => _$DisputeFromJson(json);
  Map<String, dynamic> toJson() => _$DisputeToJson(this);
}