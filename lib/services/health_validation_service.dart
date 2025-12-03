import 'package:flutter/material.dart';

/// Health validation service with BMI calculations and safety checks
class HealthValidationService {
  /// Calculate BMI from height (cm) and weight (kg)
  static double calculateBMI(double heightCm, double weightKg) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI category and warning
  static HealthValidation validateBMI(double bmi) {
    if (bmi < 16) {
      return HealthValidation(
        isValid: false,
        severity: ValidationSeverity.critical,
        message:
            '⚠️ Severely underweight - Please consult a doctor before starting any fitness program',
        recommendation: 'Focus on nutrition and gentle activities',
      );
    } else if (bmi < 18.5) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.warning,
        message: '⚠️ Underweight - Challenges adjusted for safety',
        recommendation: 'Strength training and balanced nutrition recommended',
      );
    } else if (bmi >= 18.5 && bmi < 25) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.normal,
        message: '✅ Healthy weight range',
        recommendation: null,
      );
    } else if (bmi >= 25 && bmi < 30) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'ℹ️ Overweight - Moderate intensity recommended',
        recommendation: 'Focus on cardio and gradual progression',
      );
    } else if (bmi >= 30 && bmi < 35) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.warning,
        message: '⚠️ Obese (Class I) - Low-impact activities suggested',
        recommendation: 'Walking, swimming, and diet management',
      );
    } else {
      return HealthValidation(
        isValid: false,
        severity: ValidationSeverity.critical,
        message: '⚠️ Please consult a healthcare provider before starting',
        recommendation: 'Medical supervision recommended for exercise',
      );
    }
  }

  /// Validate age and provide age-appropriate recommendations
  static HealthValidation validateAge(int age) {
    if (age < 16) {
      return HealthValidation(
        isValid: false,
        severity: ValidationSeverity.critical,
        message: '⚠️ Parental guidance required for users under 16',
        recommendation: 'Consult with a pediatrician',
      );
    } else if (age >= 16 && age < 25) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.normal,
        message: '✅ Peak performance years',
        recommendation: 'Higher intensity training suitable',
      );
    } else if (age >= 25 && age < 50) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.normal,
        message: '✅ Adult fitness range',
        recommendation: 'Balanced training approach',
      );
    } else if (age >= 50 && age < 65) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'ℹ️ Focus on joint-friendly exercises',
        recommendation: 'Include flexibility and balance training',
      );
    } else {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.warning,
        message: '⚠️ Low-impact activities recommended',
        recommendation: 'Prioritize safety and gentle progression',
      );
    }
  }

  /// Check for conflicting selections
  static HealthValidation validateChallengeCompatibility({
    required String challengeType,
    required List<String> medicalConditions,
    required String fitnessLevel,
    required int age,
  }) {
    final List<String> warnings = [];

    // Check medical conditions vs challenge type
    if (medicalConditions.contains('Joint Issues')) {
      if (challengeType == 'activityStrength') {
        warnings
            .add('⚠️ Joint issues detected - Consider low-impact alternatives');
      }
    }

    if (medicalConditions.contains('Heart Condition')) {
      warnings.add(
          '⚠️ Heart condition - Please get medical clearance before starting');
    }

    if (medicalConditions.contains('High BP') &&
        challengeType == 'activityStrength') {
      warnings.add('⚠️ Monitor blood pressure during intense workouts');
    }

    // Check age + fitness level combination
    if (age < 25 &&
        fitnessLevel == 'Beginner' &&
        challengeType == 'activityStrength') {
      warnings.add(
          'ℹ️ Great choice! Youth + strength training = excellent results');
    }

    if (age > 60 && fitnessLevel == 'Advanced') {
      warnings
          .add('💪 Impressive! Maintain excellent form to prevent injuries');
    }

    if (warnings.isEmpty) {
      return HealthValidation(
        isValid: true,
        severity: ValidationSeverity.normal,
        message: '✅ Challenge compatible with your profile',
        recommendation: null,
      );
    }

    return HealthValidation(
      isValid: true,
      severity: warnings.any((w) => w.contains('⚠️'))
          ? ValidationSeverity.warning
          : ValidationSeverity.info,
      message: warnings.join('\n'),
      recommendation: null,
    );
  }

  /// Calculate recommended daily calorie adjustment
  static int calculateCalorieAdjustment({
    required double bmi,
    required int age,
    required String activityLevel,
    required String challengeType,
  }) {
    int baseCalories = 0;

    // Challenge type baseline
    if (challengeType == 'weightManagement') {
      baseCalories = bmi > 25 ? -300 : -200; // Deficit for weight loss
    } else if (challengeType == 'activityStrength') {
      baseCalories = 200; // Surplus for muscle building
    }

    // Activity level multiplier
    final activityMultiplier = {
          'Sedentary': 0.8,
          'Lightly Active': 1.0,
          'Moderately Active': 1.2,
          'Very Active': 1.4,
          'Extremely Active': 1.6,
        }[activityLevel] ??
        1.0;

    // Age adjustment
    final ageAdjustment = age > 50 ? 0.9 : 1.0;

    return (baseCalories * activityMultiplier * ageAdjustment).round();
  }

  /// Get health risk score (0-100, lower is better)
  static int calculateHealthRiskScore({
    required double bmi,
    required int age,
    required List<String> medicalConditions,
    required double sleepQuality,
    required double stressLevel,
  }) {
    int score = 0;

    // BMI contribution (0-30 points)
    if (bmi < 18.5 || bmi > 30) {
      score += 30;
    } else if (bmi < 20 || bmi > 27) {
      score += 15;
    }

    // Age contribution (0-15 points)
    if (age > 65)
      score += 15;
    else if (age > 50)
      score += 10;
    else if (age < 18) score += 10;

    // Medical conditions (0-25 points)
    score += medicalConditions.where((c) => c != 'None').length * 8;
    score = score.clamp(0, 25); // Cap at 25

    // Sleep quality (0-15 points, inverted)
    score += ((5 - sleepQuality) * 3).round();

    // Stress level (0-15 points)
    score += (stressLevel * 3).round();

    return score.clamp(0, 100);
  }
}

enum ValidationSeverity {
  normal, // Green
  info, // Blue
  warning, // Orange
  critical // Red
}

class HealthValidation {
  final bool isValid;
  final ValidationSeverity severity;
  final String message;
  final String? recommendation;

  HealthValidation({
    required this.isValid,
    required this.severity,
    required this.message,
    this.recommendation,
  });

  Color getColor() {
    switch (severity) {
      case ValidationSeverity.normal:
        return Colors.green;
      case ValidationSeverity.info:
        return Colors.blue;
      case ValidationSeverity.warning:
        return Colors.orange;
      case ValidationSeverity.critical:
        return Colors.red;
    }
  }

  IconData getIcon() {
    switch (severity) {
      case ValidationSeverity.normal:
        return Icons.check_circle;
      case ValidationSeverity.info:
        return Icons.info;
      case ValidationSeverity.warning:
        return Icons.warning;
      case ValidationSeverity.critical:
        return Icons.error;
    }
  }
}
