import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/toast_helper.dart';
import '../state/calls_provider.dart';

class RateCallBottomSheet extends StatefulWidget {
  final String callId;

  const RateCallBottomSheet({super.key, required this.callId});

  @override
  State<RateCallBottomSheet> createState() => _RateCallBottomSheetState();
}

class _RateCallBottomSheetState extends State<RateCallBottomSheet> {
  int rating = 0;

  final TextEditingController comment = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CallsProvider>();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 25),

          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xffEEF4FF),
            child: Icon(Icons.star, color: Colors.amber, size: 34),
          ),

          const SizedBox(height: 18),

          const Text(
            "Rate your call",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            "How was your experience?",
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    rating = index + 1;
                  });
                },
                icon: Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: index < rating ? Colors.amber : Colors.grey.shade300,
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: comment,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Leave a comment...",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: loading || rating == 0
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                      });

                      try {
                        await provider.rateCall(
                          widget.callId,
                          rating,
                          comment.text.trim(),
                        );

                        Get.back();

                        ToastHelper.showSuccessToast(
                          message: "Your rating has been submitted.",
                        );
                      } catch (e) {
                        ToastHelper.showErrorToast(message: e.toString());
                      }

                      setState(() {
                        loading = false;
                      });
                    },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Submit Rating",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
