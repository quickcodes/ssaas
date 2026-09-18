import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ManualStep extends Equatable {
  final String title;
  final String description;
  final IconData? icon;

  const ManualStep({
    required this.title,
    required this.description,
    this.icon,
  });

  @override
  List<Object?> get props => [title, description, icon];
}

class ManualFaq extends Equatable {
  final String question;
  final String answer;

  const ManualFaq({
    required this.question,
    required this.answer,
  });

  @override
  List<Object?> get props => [question, answer];
}

class ManualCalculationExample extends Equatable {
  final String title;
  final String scenario;
  final List<String> breakdown;
  final String totalResult;
  final String explanation;

  const ManualCalculationExample({
    required this.title,
    required this.scenario,
    required this.breakdown,
    required this.totalResult,
    required this.explanation,
  });

  @override
  List<Object?> get props => [
        title,
        scenario,
        breakdown,
        totalResult,
        explanation,
      ];
}

class ManualSection extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color themeColor;
  final List<String> tags;
  final String overview;
  final List<String> keyObjectives;
  final List<ManualStep> stepByStepFlow;
  final List<String> businessRules;
  final List<String> proTips;
  final List<ManualFaq> faqs;
  final List<ManualCalculationExample> examples;

  const ManualSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.themeColor,
    required this.tags,
    required this.overview,
    required this.keyObjectives,
    required this.stepByStepFlow,
    required this.businessRules,
    required this.proTips,
    required this.faqs,
    this.examples = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        category,
        icon,
        themeColor,
        tags,
        overview,
        keyObjectives,
        stepByStepFlow,
        businessRules,
        proTips,
        faqs,
        examples,
      ];
}
