import 'package:flutter/material.dart';
import '../theme/eco_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_constants.dart';

/// Centralized loading widget
class EcoLoadingIndicator extends StatelessWidget {
  const EcoLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.message,
  });

  final double size;
  final Color? color;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? EcoColors.primary,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spacingL),
            Text(
              message!,
              style: const TextStyle(
                color: EcoColors.bodyMuted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading widget for full screen
class EcoFullScreenLoading extends StatelessWidget {
  const EcoFullScreenLoading({
    super.key,
    this.message = AppStrings.loadingPleaseWait,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.welcomeGradientEnd,
      body: EcoLoadingIndicator(message: message),
    );
  }
}

/// Error widget with retry button
class EcoErrorWidget extends StatelessWidget {
  const EcoErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.paddingXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: EcoColors.coral,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              message,
              style: const TextStyle(
                color: EcoColors.bodyMuted,
                fontSize: AppConstants.fontSizeL,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spacingXxl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: EcoColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class EcoEmptyState extends StatelessWidget {
  const EcoEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.paddingXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: EcoColors.sheetHandle,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              message,
              style: const TextStyle(
                color: EcoColors.bodyMuted,
                fontSize: AppConstants.fontSizeL,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: AppConstants.spacingXxl),
              FilledButton(
                onPressed: action,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stream builder wrapper with loading and error states
class EcoStreamBuilder<T> extends StatelessWidget {
  const EcoStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
  });

  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget? emptyWidget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const EcoLoadingIndicator();
        }

        // Error state
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!);
          }
          return EcoErrorWidget(
            message: snapshot.error.toString(),
          );
        }

        // Empty state (for lists)
        if (!snapshot.hasData) {
          return emptyWidget ?? const EcoEmptyState(message: AppStrings.errorNoData);
        }

        // Success state
        return builder(context, snapshot.data as T);
      },
    );
  }
}

/// Future builder wrapper with loading and error states
class EcoFutureBuilder<T> extends StatelessWidget {
  const EcoFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const EcoLoadingIndicator();
        }

        // Error state
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!);
          }
          return EcoErrorWidget(
            message: snapshot.error.toString(),
          );
        }

        // Success state
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        // No data
        return const EcoEmptyState(message: AppStrings.errorNoData);
      },
    );
  }
}
