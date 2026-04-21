/**
 * dama — Cloud Functions
 *
 * Kakao access token → Firebase custom token 교환 엔드포인트.
 * iOS 앱은 이 함수를 호출하여 Firebase Auth에 로그인합니다.
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

// 전역 옵션 — 서울 리전, 합리적 기본값
setGlobalOptions({
  region: "asia-northeast3",
  maxInstances: 10,
  serviceAccount: "firebase-adminsdk-fbsvc@dama-382bb.iam.gserviceaccount.com",
});

initializeApp();

// MARK: - Types

interface KakaoUserResponse {
  id: number;
  kakao_account?: {
    email?: string;
    profile?: {
      nickname?: string;
      profile_image_url?: string;
    };
  };
}

interface KakaoSignInInput {
  accessToken: string;
}

interface KakaoSignInOutput {
  firebaseToken: string;
  uid: string;
  isNewUser: boolean;
}

// MARK: - kakaoSignIn

/**
 * Kakao access token을 검증하고 Firebase custom token을 반환합니다.
 *
 * 호출 시 앱은 KakaoSDKUser에서 발급받은 access token을 전달합니다.
 * 서버는 이 토큰으로 /v2/user/me 를 호출해 유저 정보를 받고,
 * `kakao:{id}` 형태의 uid로 Firebase custom token을 발급합니다.
 */
export const kakaoSignIn = onCall<KakaoSignInInput, Promise<KakaoSignInOutput>>(
  {cors: true},
  async (request) => {
    const {accessToken} = request.data;

    if (!accessToken || typeof accessToken !== "string") {
      throw new HttpsError("invalid-argument", "accessToken이 필요합니다.");
    }

    // 1. Kakao access token 검증 — 유저 정보 조회
    let kakaoUser: KakaoUserResponse;
    try {
      const response = await fetch("https://kapi.kakao.com/v2/user/me", {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        },
      });

      if (!response.ok) {
        const body = await response.text();
        logger.warn("Kakao /v2/user/me 실패", {
          status: response.status,
          body,
        });
        throw new HttpsError(
          "unauthenticated",
          "Kakao 토큰 검증에 실패했습니다."
        );
      }

      kakaoUser = (await response.json()) as KakaoUserResponse;
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Kakao API 호출 예외", error);
      throw new HttpsError("internal", "Kakao API 호출에 실패했습니다.");
    }

    // 2. uid 구성 — 'kakao:' prefix로 다른 provider와 충돌 방지
    const kakaoId = kakaoUser.id.toString();
    const uid = `kakao:${kakaoId}`;

    const email = kakaoUser.kakao_account?.email;
    const nickname =
      kakaoUser.kakao_account?.profile?.nickname ?? "담아 사용자";
    const profileImageURL =
      kakaoUser.kakao_account?.profile?.profile_image_url;

    // 3. Firestore User 문서 upsert
    //    클라이언트도 동일한 로직이 있지만 서버에서 먼저 써야
    //    custom token 로그인 직후 데이터가 준비되어 있음.
    const userRef = getFirestore().collection("users").doc(uid);
    const existing = await userRef.get();
    const isNewUser = !existing.exists;

    if (isNewUser) {
      await userRef.set({
        email: email ?? null,
        name: nickname,
        profileImageURL: profileImageURL ?? null,
        groupIds: [],
        fcmToken: null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      // 기존 유저는 프로필 정보만 최신화 (name·이미지)
      await userRef.update({
        name: nickname,
        profileImageURL: profileImageURL ?? null,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // 4. Firebase custom token 발급
    const additionalClaims = {
      provider: "kakao",
    };
    const firebaseToken = await getAuth().createCustomToken(
      uid,
      additionalClaims
    );

    logger.info("Kakao 로그인 성공", {uid, isNewUser});

    return {
      firebaseToken,
      uid,
      isNewUser,
    };
  }
);
