"use client";
import * as React from "react";
import { PHONE_SCREEN } from "@/lib/constants";
import { img } from "@/lib/image-cache";

type FrameProps = {
  src: string;
  alt?: string;
  style?: React.CSSProperties;
  /** When true, hide EmptySlot placeholder (so it doesn't bake into exports). */
  hideEmpty?: boolean;
  showCameraDot?: boolean;
};

// iPhone — uses pre-measured mockup.png overlay
export function Phone({ src, alt = "", style, hideEmpty }: FrameProps) {
  const resolved = img(src);
  return (
    <div style={{ position: "relative", aspectRatio: "1022 / 2082", ...style }}>
      <img
        src={img("/mockup.png")}
        alt=""
        style={{ display: "block", width: "100%", height: "100%" }}
        draggable={false}
      />
      <div
        style={{
          position: "absolute",
          zIndex: 10,
          overflow: "hidden",
          left: `${PHONE_SCREEN.L}%`,
          top: `${PHONE_SCREEN.T}%`,
          width: `${PHONE_SCREEN.W}%`,
          height: `${PHONE_SCREEN.H}%`,
          borderRadius: `${PHONE_SCREEN.RX}% / ${PHONE_SCREEN.RY}%`,
          background: "#111",
        }}
      >
        {resolved ? (
          <img
            src={resolved}
            alt={alt}
            style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
            draggable={false}
          />
        ) : hideEmpty ? null : (
          <EmptySlot />
        )}
      </div>
    </div>
  );
}

export function AndroidPhone({
  src,
  alt = "",
  style,
  hideEmpty,
  showCameraDot = false,
}: FrameProps) {
  const resolved = img(src);

  const left = "1.5%";
  const top = "0.7%";
  const width = "97%";
  const height = "98.6%";
  const borderRadius = "6.8% / 3.4%";

  return (
    <div style={{ position: "relative", aspectRatio: "9 / 19.5", ...style }}>
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: "8% / 4%",
          background: "linear-gradient(160deg, #2a2a2e 0%, #18181b 100%)",
          boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.08), 0 8px 40px rgba(0,0,0,0.55)",
          position: "relative",
          overflow: "hidden",
        }}
      >
        {showCameraDot && (
          <div
            style={{
              position: "absolute",
              top: "1.5%",
              left: "50%",
              transform: "translateX(-50%)",
              width: "3%",
              height: "1.4%",
              borderRadius: "50%",
              background: "#0d0d0f",
              border: "1px solid rgba(255,255,255,0.06)",
              zIndex: 20,
            }}
          />
        )}
        <div
          style={{
            position: "absolute",
            left,
            top,
            width,
            height,
            borderRadius,
            overflow: "hidden",
            background: "#000",
          }}
        >
          {resolved ? (
            <img
              src={resolved}
              alt={alt}
              style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
              draggable={false}
            />
          ) : hideEmpty ? null : (
            <EmptySlot />
          )}
        </div>
      </div>
    </div>
  );
}

export function AndroidTabletP({
  src,
  alt = "",
  style,
  hideEmpty,
  showCameraDot = false,
}: FrameProps) {
  const resolved = img(src);

  // Hardcoded to thin bezels (the only frame option)
  const left = "1.5%";
  const top = "0.9%";
  const width = "97%";
  const height = "98.2%";
  const borderRadius = "3.1% / 1.9%";

  return (
    <div style={{ position: "relative", aspectRatio: "5 / 8", ...style }}>
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: "4.5% / 2.8%",
          background: "linear-gradient(160deg, #2a2a2e 0%, #18181b 100%)",
          boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.08), 0 8px 48px rgba(0,0,0,0.6)",
          position: "relative",
          overflow: "hidden",
        }}
      >
        {showCameraDot && (
          <div
            style={{
              position: "absolute",
              top: "1.2%",
              left: "50%",
              transform: "translateX(-50%)",
              width: "1.4%",
              height: "0.88%",
              borderRadius: "50%",
              background: "#0d0d0f",
              zIndex: 20,
            }}
          />
        )}
        <div
          style={{
            position: "absolute",
            left,
            top,
            width,
            height,
            borderRadius,
            overflow: "hidden",
            background: "#000",
          }}
        >
          {resolved ? (
            <img
              src={resolved}
              alt={alt}
              style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
              draggable={false}
            />
          ) : hideEmpty ? null : (
            <EmptySlot />
          )}
        </div>
      </div>
    </div>
  );
}

export function AndroidTabletL({
  src,
  alt = "",
  style,
  hideEmpty,
  showCameraDot = false,
}: FrameProps) {
  const resolved = img(src);

  // Hardcoded to thin bezels (the only frame option)
  const left = "0.9%";
  const top = "1.5%";
  const width = "98.2%";
  const height = "97%";
  const borderRadius = "1.9% / 3.1%";

  return (
    <div style={{ position: "relative", aspectRatio: "8 / 5", ...style }}>
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: "2.8% / 4.5%",
          background: "linear-gradient(160deg, #2a2a2e 0%, #18181b 100%)",
          boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.08), 0 8px 48px rgba(0,0,0,0.6)",
          position: "relative",
          overflow: "hidden",
        }}
      >
        {showCameraDot && (
          <div
            style={{
              position: "absolute",
              left: "1.2%",
              top: "50%",
              transform: "translateY(-50%)",
              width: "0.88%",
              height: "1.4%",
              borderRadius: "50%",
              background: "#0d0d0f",
              zIndex: 20,
            }}
          />
        )}
        <div
          style={{
            position: "absolute",
            left,
            top,
            width,
            height,
            borderRadius,
            overflow: "hidden",
            background: "#000",
          }}
        >
          {resolved ? (
            <img
              src={resolved}
              alt={alt}
              style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
              draggable={false}
            />
          ) : hideEmpty ? null : (
            <EmptySlot />
          )}
        </div>
      </div>
    </div>
  );
}

export function IPad({
  src,
  alt = "",
  style,
  hideEmpty,
  showCameraDot = false,
}: FrameProps) {
  const resolved = img(src);

  // Hardcoded to thin bezels (the only frame option)
  const left = "1.8%";
  const top = "1.4%";
  const width = "96.4%";
  const height = "97.2%";
  const borderRadius = "3.3% / 2.3%";

  return (
    <div style={{ position: "relative", aspectRatio: "770 / 1000", ...style }}>
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: "5% / 3.6%",
          background: "linear-gradient(180deg, #2C2C2E 0%, #1C1C1E 100%)",
          position: "relative",
          overflow: "hidden",
          boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.1), 0 8px 40px rgba(0,0,0,0.6)",
        }}
      >
        {showCameraDot && (
          <div
            style={{
              position: "absolute",
              top: "1.2%",
              left: "50%",
              transform: "translateX(-50%)",
              width: "0.9%",
              height: "0.65%",
              borderRadius: "50%",
              background: "#111113",
              zIndex: 20,
            }}
          />
        )}
        <div
          style={{
            position: "absolute",
            left,
            top,
            width,
            height,
            borderRadius,
            overflow: "hidden",
            background: "#000",
          }}
        >
          {resolved ? (
            <img
              src={resolved}
              alt={alt}
              style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
              draggable={false}
            />
          ) : hideEmpty ? null : (
            <EmptySlot />
          )}
        </div>
      </div>
    </div>
  );
}

function EmptySlot() {
  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        color: "rgba(255,255,255,0.4)",
        fontSize: "min(2vw, 14px)",
        background: "linear-gradient(135deg, #1a1a1a 0%, #0a0a0a 100%)",
        textAlign: "center",
        padding: "4%",
      }}
    >
      Drop a screenshot here
    </div>
  );
}
