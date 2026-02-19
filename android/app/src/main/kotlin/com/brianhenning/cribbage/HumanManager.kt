package com.brianhenning.cribbage

import android.app.Application
import com.humansecurity.mobile_sdk.HumanSecurity
import com.humansecurity.mobile_sdk.main.HSBotDefenderChallengeResult
import com.humansecurity.mobile_sdk.main.policy.HSAutomaticInterceptorType
import com.humansecurity.mobile_sdk.main.policy.HSPolicy
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class HumanManager {
    companion object {
        fun start(application: Application) {
            try {
                val policy = HSPolicy()
                policy.automaticInterceptorPolicy.interceptorType =
                    HSAutomaticInterceptorType.NONE
                HumanSecurity.start(application, "PX_APP_ID", policy)
            } catch (exception: Exception) {
                println("Exception: ${exception.message}")
            }
        }

        fun handleEvent(
            call: MethodCall,
            result: MethodChannel.Result
        ) {
            if (call.method == "humanGetHeaders") {
                val json = JSONObject(
                    HumanSecurity.BD.headersForURLRequest(null)
                        as Map<*, *>
                )
                result.success(json.toString())
            } else if (call.method == "humanHandleResponse") {
                val handled = HumanSecurity.BD.handleResponse(
                    call.arguments!! as String
                ) { challengeResult: HSBotDefenderChallengeResult ->
                    result.success(
                        if (challengeResult ==
                            HSBotDefenderChallengeResult.SOLVED
                        ) "solved" else "cancelled"
                    )
                    null
                }
                if (!handled) {
                    result.success("false")
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
