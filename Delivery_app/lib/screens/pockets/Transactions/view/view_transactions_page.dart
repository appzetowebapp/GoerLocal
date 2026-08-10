import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hyper_local/l10n/app_localizations.dart';

import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../bloc/wallet_transactions_bloc.dart';
import '../widgets/empty_transaction_widget.dart';
import '../widgets/transaction_card.dart';

class ViewTransactionsPage extends StatefulWidget {
  const ViewTransactionsPage({super.key});

  @override
  State<ViewTransactionsPage> createState() => _ViewTransactionsPageState();
}

class _ViewTransactionsPageState extends State<ViewTransactionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletTransactionsBloc>().add(FetchWalletTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBarWithoutNavbar(title: AppLocalizations.of(context)!.transactions),

      body: BlocBuilder<WalletTransactionsBloc, WalletTransactionsState>(
        builder: (BuildContext context, WalletTransactionsState state) {
          if (state.status == WalletTransactionsStatus.success ||
              (state.status == WalletTransactionsStatus.loading && state.transactions.isNotEmpty)) {
            if (state.transactions.isEmpty) {
              return EmptyTransactionsState(
                onRetry: () {
                  context.read<WalletTransactionsBloc>().add(FetchWalletTransactions());
                },
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo is ScrollUpdateNotification &&
                    !state.hasReachedMax &&
                    scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50) {
                  context.read<WalletTransactionsBloc>().add(FetchMoreWalletTransactions());
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<WalletTransactionsBloc>().add(FetchWalletTransactions());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.hasReachedMax ? state.transactions.length : state.transactions.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= state.transactions.length) {
                      return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
                    }

                    return TransactionCard(transaction: state.transactions[index]);
                  },
                ),
              ),
            );
          }
          if (state.status == WalletTransactionsStatus.failure) {
            return EmptyTransactionsState(
              onRetry: () {
                context.read<WalletTransactionsBloc>().add(FetchWalletTransactions());
              },
            );
          }
          if (state.status == WalletTransactionsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return EmptyTransactionsState(
            onRetry: () {
              context.read<WalletTransactionsBloc>().add(FetchWalletTransactions());
            },
          );
        },
      ),
    );
  }
}
