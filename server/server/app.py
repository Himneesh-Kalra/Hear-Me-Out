from eventlet import monkey_patch
monkey_patch()  # ✅ Must be the first import!
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.image import img_to_array
import mediapipe as mp
import base64
import cv2
import numpy as np
from flask import Flask, request
from flask_socketio import SocketIO, emit
import logging
import signal
import sys

# 🔥 Define label mapping (Ensure this matches the dataset classes in the same order!)
LABELS = [
    "0","1","2","3","4","5","6","7","8","9","A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
]  # Modify based on your dataset


# ✅ Configure logging for better debugging
logging.basicConfig(level=logging.INFO)

# ✅ Load ML Model
MODEL_PATH = "C:/majorproject/server/asl_cnn4_model (1).h5"  # Replace with actual model path
model = load_model(MODEL_PATH)
logging.info("✅ Model Loaded Successfully!")

# ✅ Initialize Mediapipe Hands module
mp_hands = mp.solutions.hands
mp_draw = mp.solutions.drawing_utils
hands = mp_hands.Hands(static_image_mode=True, max_num_hands=1, min_detection_confidence=0.5)

# ✅ Flask WebSocket Server Setup
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")

@app.route("/")
def index():
    return "Flask WebSocket Server is running!"

@app.before_request
def log_request():
    if request.path != "/socket.io/":
        logging.info(f"📥 Incoming HTTP request: {request.method} {request.path}")

@socketio.on("connect")
def handle_connect():
    logging.info(f"✅ WebSocket client connected: {request.sid}")
    emit("message", "Connected to WebSocket server")

@socketio.on("disconnect")
def handle_disconnect():
    logging.info(f"❌ WebSocket client disconnected: {request.sid}")

@socketio.on("frame")
def handle_frame(data):
    logging.info(f"📸 Received frame from {request.sid}")
    try:
        image_data = base64.b64decode(data)
        np_arr = np.frombuffer(image_data, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        if frame is None:
            raise ValueError("Failed to decode image frame")

        sign_text = recognize_sign(frame)
        emit("translation", sign_text)
    except Exception as e:
        logging.error(f"⚠️ Error processing frame: {e}")
        emit("error", f"Failed to process frame: {str(e)}")

# ✅ Hand Detection and Processing
def detect_and_crop_hand(image):
    img_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    h, w, _ = image.shape
    results = hands.process(img_rgb)

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            x_min = int(min(lm.x for lm in hand_landmarks.landmark) * w)
            y_min = int(min(lm.y for lm in hand_landmarks.landmark) * h)
            x_max = int(max(lm.x for lm in hand_landmarks.landmark) * w)
            y_max = int(max(lm.y for lm in hand_landmarks.landmark) * h)

            hand_crop = image[y_min:y_max, x_min:x_max]
            if hand_crop.size == 0:
                return None
            return resize_with_padding(hand_crop, 128, 128)  # Resize to model input size
    return None

# ✅ Resize Image with Padding
def resize_with_padding(image, target_width, target_height):
    h, w = image.shape[:2]
    scale = min(target_width / w, target_height / h)
    new_w, new_h = int(w * scale), int(h * scale)
    resized = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)
    padded = np.zeros((target_height, target_width, 3), dtype=np.uint8)
    x_offset = (target_width - new_w) // 2
    y_offset = (target_height - new_h) // 2
    padded[y_offset:y_offset+new_h, x_offset:x_offset+new_w] = resized
    return padded

# ✅ Predict Sign Language Gesture
def recognize_sign(frame):
    hand_img = detect_and_crop_hand(frame)
    if hand_img is not None:
        # Save resized hand image for debugging
        cv2.imwrite("resized_hand.jpg", hand_img)
        
        img_array = img_to_array(hand_img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)
        print("Model Input Shape:", img_array.shape)  # Should print (1, 128, 128, 3)

        predictions = model.predict(img_array)
        predicted_class = int(np.argmax(predictions))

        # ✅ Convert class index to actual label
        if predicted_class < len(LABELS):
            predicted_label = LABELS[predicted_class]
        else:
            predicted_label = "Unknown"

        return predicted_label  # Return actual class name
    return "No hand detected"

# ✅ Handle Server Shutdown Properly
def shutdown_server():
    logging.info("\nShutting down Flask WebSocket server...")
    cv2.destroyAllWindows()
    sys.exit(0)

signal.signal(signal.SIGINT, lambda signal, frame: shutdown_server())

if __name__ == "__main__":
    logging.info("🚀 Starting WebSocket server on ws://0.0.0.0:5000")
    socketio.run(app, host="0.0.0.0", port=5000, log_output=True)
