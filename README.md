# PrecisionPointer Research Application

A comprehensive iOS research application designed to evaluate the effectiveness of precision text selection methods on mobile devices. This project implements and tests "PrecisionPointer" - a novel interaction paradigm for accurate text selection on touchscreens.

## 📋 Project Overview

Standard text selection on mobile touchscreens often suffers from the "fat finger" problem, where users' fingers occlude the text they're trying to select, leading to frequent errors and poor user experience. PrecisionPointer addresses this by introducing a gesture-activated precision mode that provides magnified text selection capabilities.

### Research Hypothesis
> PrecisionPointer will demonstrate statistically significant improvement in both speed and accuracy for precision-oriented tasks and will receive higher subjective satisfaction ratings compared to standard text selection methods.

## 🏗️ Architecture

### iOS Application (SwiftUI)
- **Main App**: `Precision_KeyboardApp.swift` - Entry point and app configuration
- **Root View**: `RootView.swift` - Navigation and study flow management
- **Study Session**: `StudySessionStore.swift` - Task management and data collection
- **Precision Editor**: Complete precision mode implementation with magnified text selection
- **SUS Survey**: System Usability Scale questionnaire for user satisfaction

### Backend Server (Go)
- **Data Collection**: REST API for collecting comprehensive metrics
- **CSV Export**: Automated data export for statistical analysis
- **Session Management**: Participant tracking and counterbalancing

## 🚀 Features

### Enhanced Precision Mode
- **Gesture Activation**: Long-press to activate precision mode
- **Full-Screen Magnification**: 3x text magnification for accurate selection
- **Persistent Mode**: Release finger to continue selecting from magnified view
- **Smart Exit**: Tap empty space to exit precision mode
- **Elegant UI**: Beautiful animations and visual feedback

### Comprehensive Study Design
- **Training Tasks**: 2 practice tasks to familiarize users with both methods
- **Main Study Tasks**: 16 tasks with diverse text types and difficulty levels
- **Counterbalancing**: Proper randomization of method order across participants
- **Progress Tracking**: Visual progress indicators and task completion feedback

### Advanced Data Collection
- **25+ Metrics**: Comprehensive performance tracking including:
  - Task completion time and accuracy
  - Gesture analysis (taps, long-presses, drags)
  - Precision mode usage patterns
  - Selection accuracy scores
  - Error rates and correction patterns
- **SUS Survey**: Standardized usability assessment
- **Real-time Logging**: Detailed console output for monitoring

## 📊 Study Design

### Task Types
- **Single Words**: Basic word selection tasks
- **Phrases**: Multi-word phrase selection
- **Sentences**: Complete sentence selection
- **Paragraphs**: Extended text selection

### Difficulty Levels
- **Easy**: Simple, common words
- **Medium**: Standard complexity text
- **Hard**: Complex phrases with time limits

### Methods Comparison
- **Standard Selection**: Native iOS text selection method
- **Precision Mode**: Novel magnified text selection approach

## 🛠️ Setup Instructions

### Prerequisites
- macOS with Xcode 15.0+
- iOS 18.5+ device or simulator
- Go 1.21+ for backend server

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd goBackend
   ```

2. Start the Go server:
   ```bash
   go run main.go
   ```
   The server will start on `http://localhost:8080`

3. Access the Interactive Dashboard:
   Open your browser and navigate to `http://localhost:8080` or `http://localhost:8080/dashboard`
   The dashboard provides real-time visualization of all collected research data.

### iOS App Setup
1. Open `Precision Keyboard.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the application
4. The app will automatically connect to the backend server

## 📱 Usage

### For Participants
1. **Welcome Screen**: Enter participant ID and provide consent
2. **Instructions**: Review study instructions and interaction methods
3. **Training Tasks**: Practice with both selection methods
4. **Main Study**: Complete 16 tasks with alternating methods
5. **SUS Survey**: Complete usability questionnaire
6. **Completion**: Study completion confirmation

### For Researchers
1. **Start Backend**: Ensure Go server is running
2. **Monitor Logs**: Watch console output for real-time data collection
3. **Data Export**: Check `study_results.csv` and `sus_responses.csv` files
4. **Analysis**: Import CSV files into statistical analysis software

## 📊 Interactive Dashboard

The research dashboard provides real-time visualization and analysis of all collected data. Access it by opening `http://localhost:8080` in your browser after starting the backend server.

### Dashboard Features

- **Real-time Data Visualization**: 
  - Completion time comparison between methods
  - Accuracy score analysis
  - Performance distribution charts
  - Task difficulty analysis
  - Precision mode usage statistics
  - SUS score distribution

- **Interactive Filters**:
  - Filter by participant
  - Filter by selection method (standard/precision)
  - Filter by task difficulty (easy/medium/hard)
  - Auto-refresh every 30 seconds

- **Summary Statistics**:
  - Total participants and tasks completed
  - Average completion time
  - Average accuracy scores
  - Average SUS scores

- **Data Export**:
  - Export filtered data as CSV
  - Download complete dataset for analysis

- **Recent Task Table**:
  - View last 20 completed tasks
  - See participant, method, time, accuracy, and status

### Dashboard API Endpoints

- `GET /api/metrics` - Get all metrics as JSON
- `GET /api/sus` - Get all SUS survey responses as JSON
- `GET /` or `/dashboard` - Access the dashboard interface

## 📈 Data Collection

### Metrics Collected
- **Performance Metrics**:
  - Task completion time (milliseconds)
  - Selection accuracy (0.0-1.0 scale)
  - Error count and correction patterns
  - Average selection speed

- **Interaction Metrics**:
  - Gesture counts (taps, long-presses, drags)
  - Precision mode activations and duration
  - Selection adjustment counts
  - Excess travel distance

- **User Experience**:
  - System Usability Scale (SUS) scores
  - Task difficulty ratings
  - Method preference indicators

### Data Export
- **study_results.csv**: Comprehensive task performance data
- **sus_responses.csv**: User satisfaction survey responses
- **Real-time Logging**: Console output for debugging and monitoring

## 🔧 Technical Details

### iOS Implementation
- **SwiftUI**: Modern declarative UI framework
- **UIKit Integration**: Custom text view components for precision selection
- **State Management**: ObservableObject pattern for reactive data flow
- **Offline Support**: Data queuing when backend is unavailable

### Backend Implementation
- **Go HTTP Server**: Lightweight REST API
- **JSON Communication**: Structured data exchange
- **CSV Export**: Automated data persistence
- **CORS Support**: Cross-origin resource sharing

### Data Models
- **StudyTask**: Task definition with metadata
- **MetricEvent**: Comprehensive performance metrics
- **SUSSubmission**: Usability survey responses
- **Session Management**: Participant tracking and counterbalancing

## 🧪 Research Methodology

### Study Type
- **Within-Subjects Design**: All participants use both methods
- **Counterbalanced Order**: Method order randomized across participants
- **Training Phase**: Practice tasks before main study
- **Quantitative Analysis**: Statistical comparison of performance metrics

### Statistical Analysis
The collected data supports various statistical analyses:
- **Paired t-tests**: Compare performance between methods
- **ANOVA**: Analyze effects of task type and difficulty
- **Correlation Analysis**: Examine relationships between metrics
- **Effect Size Calculations**: Measure practical significance

## 📄 License

This project is developed for academic research purposes. Please cite appropriately if using this work in your research.


## 🔍 Future Work

- **Eye-tracking Integration**: Analyze visual attention patterns
- **Accessibility Features**: Support for users with motor impairments
- **Multi-language Support**: Test with different languages and scripts
- **Long-term Studies**: Extended usage patterns and learning curves

---

**Note**: This application is designed for research purposes to evaluate the effectiveness of precision text selection methods on mobile devices. All data collection follows appropriate research ethics guidelines.
