package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

// Enhanced StudyResult with comprehensive metrics
type StudyResult struct {
	// Basic identification
	SessionID     string `json:"sessionId"`
	ParticipantID string `json:"participantId"`
	TaskID        string `json:"taskId"`

	// Task information
	TaskName        string `json:"taskName"`
	SelectionMethod string `json:"selectionMethod"`
	TaskDifficulty  string `json:"taskDifficulty"`
	TaskType        string `json:"taskType"`

	// Timing metrics
	StartedAt   time.Time `json:"startedAt"`
	EndedAt     time.Time `json:"endedAt"`
	TimeTakenMs int       `json:"timeTaken_ms"`

	// Interaction metrics
	TotalAdjustments     int     `json:"totalAdjustments"`
	ExcessTravel         int     `json:"excessTravel"`
	PrecisionActivations int     `json:"precisionActivations"`
	PrecisionDuration    float64 `json:"precisionDuration"`
	GestureCount         int     `json:"gestureCount"`
	LongPressCount       int     `json:"longPressCount"`
	TapCount             int     `json:"tapCount"`
	DragCount            int     `json:"dragCount"`

	// Performance metrics
	AccuracyScore         float64 `json:"accuracyScore"`
	ErrorCount            int     `json:"errorCount"`
	AverageSelectionSpeed float64 `json:"averageSelectionSpeed"`
	CompletionStatus      string  `json:"completionStatus"`

	// Selection details
	FinalSelectionStart int `json:"finalSelectionStart"`
	FinalSelectionEnd   int `json:"finalSelectionEnd"`
	TextLength          int `json:"textLength"`

	// Cognitive load (optional)
	CognitiveLoadScore *float64 `json:"cognitiveLoadScore,omitempty"`
}

// SUSSubmission represents System Usability Scale responses
type SUSSubmission struct {
	SessionID   string    `json:"sessionId"`
	Responses   []int     `json:"responses"`
	SubmittedAt time.Time `json:"submittedAt"`
}

// SessionStartRequest for session initialization
type SessionStartRequest struct {
	ParticipantID     string    `json:"participantId"`
	CounterbalanceArm int       `json:"counterbalanceArm"`
	StartedAt         time.Time `json:"startedAt"`
}

// SessionStartResponse for session initialization
type SessionStartResponse struct {
	SessionID string `json:"sessionId"`
}

// metricsHandler handles comprehensive metric data from the app
func metricsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	var result StudyResult
	err := json.NewDecoder(r.Body).Decode(&result)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Calculate time taken
	result.TimeTakenMs = int(result.EndedAt.Sub(result.StartedAt).Milliseconds())

	// Log to the console for real-time checking
	log.Printf("Received metrics: Session=%s, Task=%s, Method=%s, Time=%dms, Accuracy=%.2f\n",
		result.SessionID, result.TaskName, result.SelectionMethod, result.TimeTakenMs, result.AccuracyScore)

	// Save the data to the CSV file
	saveToCSV(result)

	// Send a success response back to the app
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "{}")
}

// sessionStartHandler handles session initialization
func sessionStartHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	var req SessionStartRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Generate a session ID (in a real app, this might be stored in a database)
	sessionID := fmt.Sprintf("session_%s_%d", req.ParticipantID, req.StartedAt.Unix())

	response := SessionStartResponse{SessionID: sessionID}

	log.Printf("Session started: ID=%s, Participant=%s, Arm=%d\n",
		sessionID, req.ParticipantID, req.CounterbalanceArm)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// susHandler handles SUS survey submissions
func susHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	var submission SUSSubmission
	err := json.NewDecoder(r.Body).Decode(&submission)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Save SUS data to separate CSV file
	saveSUSToCSV(submission)

	log.Printf("SUS submitted: Session=%s, Score=%d\n",
		submission.SessionID, calculateSUSScore(submission.Responses))

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "{}")
}

// saveToCSV handles opening, writing to, and closing the enhanced CSV file.
func saveToCSV(result StudyResult) {
	filePath := "study_results.csv"
	file, err := os.OpenFile(filePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Printf("Could not open file %s: %v\n", filePath, err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Check if the file is new to write the header
	fileInfo, _ := file.Stat()
	if fileInfo.Size() == 0 {
		header := []string{
			"SessionID", "ParticipantID", "TaskID", "TaskName", "SelectionMethod", "TaskDifficulty", "TaskType",
			"StartedAt", "EndedAt", "TimeTakenMs", "TotalAdjustments", "ExcessTravel", "PrecisionActivations",
			"PrecisionDuration", "GestureCount", "LongPressCount", "TapCount", "DragCount", "AccuracyScore",
			"ErrorCount", "AverageSelectionSpeed", "CompletionStatus", "FinalSelectionStart", "FinalSelectionEnd",
			"TextLength", "CognitiveLoadScore",
		}
		if err := writer.Write(header); err != nil {
			log.Printf("Failed to write header to CSV: %v\n", err)
		}
	}

	// Write the actual data record
	cognitiveLoadStr := ""
	if result.CognitiveLoadScore != nil {
		cognitiveLoadStr = fmt.Sprintf("%.2f", *result.CognitiveLoadScore)
	}

	record := []string{
		result.SessionID,
		result.ParticipantID,
		result.TaskID,
		result.TaskName,
		result.SelectionMethod,
		result.TaskDifficulty,
		result.TaskType,
		result.StartedAt.Format(time.RFC3339),
		result.EndedAt.Format(time.RFC3339),
		fmt.Sprintf("%d", result.TimeTakenMs),
		fmt.Sprintf("%d", result.TotalAdjustments),
		fmt.Sprintf("%d", result.ExcessTravel),
		fmt.Sprintf("%d", result.PrecisionActivations),
		fmt.Sprintf("%.3f", result.PrecisionDuration),
		fmt.Sprintf("%d", result.GestureCount),
		fmt.Sprintf("%d", result.LongPressCount),
		fmt.Sprintf("%d", result.TapCount),
		fmt.Sprintf("%d", result.DragCount),
		fmt.Sprintf("%.3f", result.AccuracyScore),
		fmt.Sprintf("%d", result.ErrorCount),
		fmt.Sprintf("%.3f", result.AverageSelectionSpeed),
		result.CompletionStatus,
		fmt.Sprintf("%d", result.FinalSelectionStart),
		fmt.Sprintf("%d", result.FinalSelectionEnd),
		fmt.Sprintf("%d", result.TextLength),
		cognitiveLoadStr,
	}
	if err := writer.Write(record); err != nil {
		log.Printf("Failed to write record to CSV: %v\n", err)
	}
}

// saveSUSToCSV saves SUS survey data to a separate CSV file
func saveSUSToCSV(submission SUSSubmission) {
	filePath := "sus_responses.csv"
	file, err := os.OpenFile(filePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Printf("Could not open file %s: %v\n", filePath, err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Check if the file is new to write the header
	fileInfo, _ := file.Stat()
	if fileInfo.Size() == 0 {
		header := []string{"SessionID", "SubmittedAt", "Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q8", "Q9", "Q10", "TotalScore"}
		if err := writer.Write(header); err != nil {
			log.Printf("Failed to write SUS header to CSV: %v\n", err)
		}
	}

	// Convert responses to strings and add total score
	responseStrings := make([]string, len(submission.Responses))
	for i, response := range submission.Responses {
		responseStrings[i] = fmt.Sprintf("%d", response)
	}

	totalScore := calculateSUSScore(submission.Responses)
	totalScoreStr := fmt.Sprintf("%d", totalScore)

	record := append([]string{
		submission.SessionID,
		submission.SubmittedAt.Format(time.RFC3339),
	}, responseStrings...)
	record = append(record, totalScoreStr)

	if err := writer.Write(record); err != nil {
		log.Printf("Failed to write SUS record to CSV: %v\n", err)
	}
}

// calculateSUSScore calculates the total SUS score from responses
func calculateSUSScore(responses []int) int {
	if len(responses) != 10 {
		return 0
	}

	total := 0
	for i, response := range responses {
		if i%2 == 0 {
			// Odd-numbered items (1, 3, 5, 7, 9): subtract 1 from score
			total += response - 1
		} else {
			// Even-numbered items (2, 4, 6, 8, 10): subtract score from 5
			total += 5 - response
		}
	}

	// Multiply by 2.5 to get final score (0-100)
	return int(float64(total) * 2.5)
}

// metricsAPIHandler serves metrics data as JSON
func metricsAPIHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	metrics := readMetricsCSV()
	json.NewEncoder(w).Encode(metrics)
}

// susAPIHandler serves SUS data as JSON
func susAPIHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	sus := readSUSCSV()
	json.NewEncoder(w).Encode(sus)
}

// dashboardHandler serves the dashboard HTML
func dashboardHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	http.ServeFile(w, r, "dashboard.html")
}

// readMetricsCSV reads the metrics CSV file and returns JSON
func readMetricsCSV() []StudyResult {
	file, err := os.Open("study_results.csv")
	if err != nil {
		return []StudyResult{}
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil || len(records) < 2 {
		return []StudyResult{}
	}

	// Skip header row
	var results []StudyResult
	for i := 1; i < len(records); i++ {
		record := records[i]
		if len(record) < 26 {
			continue
		}

		startedAt, _ := time.Parse(time.RFC3339, record[7])
		endedAt, _ := time.Parse(time.RFC3339, record[8])
		timeTaken, _ := strconv.Atoi(record[9])
		totalAdjustments, _ := strconv.Atoi(record[10])
		excessTravel, _ := strconv.Atoi(record[11])
		precisionActivations, _ := strconv.Atoi(record[12])
		precisionDuration, _ := strconv.ParseFloat(record[13], 64)
		gestureCount, _ := strconv.Atoi(record[14])
		longPressCount, _ := strconv.Atoi(record[15])
		tapCount, _ := strconv.Atoi(record[16])
		dragCount, _ := strconv.Atoi(record[17])
		accuracyScore, _ := strconv.ParseFloat(record[18], 64)
		errorCount, _ := strconv.Atoi(record[19])
		avgSelectionSpeed, _ := strconv.ParseFloat(record[20], 64)
		finalSelectionStart, _ := strconv.Atoi(record[22])
		finalSelectionEnd, _ := strconv.Atoi(record[23])
		textLength, _ := strconv.Atoi(record[24])

		var cognitiveLoad *float64
		if record[25] != "" {
			cl, _ := strconv.ParseFloat(record[25], 64)
			cognitiveLoad = &cl
		}

		result := StudyResult{
			SessionID:             record[0],
			ParticipantID:         record[1],
			TaskID:                record[2],
			TaskName:              record[3],
			SelectionMethod:       record[4],
			TaskDifficulty:        record[5],
			TaskType:              record[6],
			StartedAt:             startedAt,
			EndedAt:               endedAt,
			TimeTakenMs:           timeTaken,
			TotalAdjustments:      totalAdjustments,
			ExcessTravel:          excessTravel,
			PrecisionActivations:  precisionActivations,
			PrecisionDuration:     precisionDuration,
			GestureCount:          gestureCount,
			LongPressCount:        longPressCount,
			TapCount:              tapCount,
			DragCount:             dragCount,
			AccuracyScore:         accuracyScore,
			ErrorCount:            errorCount,
			AverageSelectionSpeed: avgSelectionSpeed,
			CompletionStatus:      record[21],
			FinalSelectionStart:   finalSelectionStart,
			FinalSelectionEnd:     finalSelectionEnd,
			TextLength:            textLength,
			CognitiveLoadScore:    cognitiveLoad,
		}
		results = append(results, result)
	}

	return results
}

// readSUSCSV reads the SUS CSV file and returns JSON
func readSUSCSV() []SUSSubmission {
	file, err := os.Open("sus_responses.csv")
	if err != nil {
		return []SUSSubmission{}
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil || len(records) < 2 {
		return []SUSSubmission{}
	}

	// Skip header row
	var submissions []SUSSubmission
	for i := 1; i < len(records); i++ {
		record := records[i]
		if len(record) < 13 {
			continue
		}

		submittedAt, _ := time.Parse(time.RFC3339, record[1])
		var responses []int
		for j := 2; j < 12; j++ {
			val, _ := strconv.Atoi(record[j])
			responses = append(responses, val)
		}

		submission := SUSSubmission{
			SessionID:   record[0],
			Responses:   responses,
			SubmittedAt: submittedAt,
		}
		submissions = append(submissions, submission)
	}

	return submissions
}

func main() {
	// Register all endpoints
	http.HandleFunc("/log", metricsHandler)                 // Legacy endpoint for backward compatibility
	http.HandleFunc("/metrics", metricsHandler)             // New comprehensive metrics endpoint
	http.HandleFunc("/sessions/start", sessionStartHandler) // Session initialization
	http.HandleFunc("/sus", susHandler)                     // SUS survey submissions
	http.HandleFunc("/api/metrics", metricsAPIHandler)      // GET metrics as JSON
	http.HandleFunc("/api/sus", susAPIHandler)              // GET SUS data as JSON
	http.HandleFunc("/dashboard", dashboardHandler)         // Dashboard HTML
	http.HandleFunc("/", dashboardHandler)                  // Dashboard as root

	port := "8080"
	log.Printf("Enhanced PrecisionPointer Research Server starting on http://localhost:%s\n", port)
	log.Printf("Available endpoints:")
	log.Printf("  GET  / or /dashboard - Interactive dashboard")
	log.Printf("  GET  /api/metrics - Get all metrics as JSON")
	log.Printf("  GET  /api/sus - Get all SUS data as JSON")
	log.Printf("  POST /metrics - Submit comprehensive task metrics")
	log.Printf("  POST /sessions/start - Initialize study session")
	log.Printf("  POST /sus - Submit SUS survey responses")
	log.Printf("  POST /log - Legacy metrics endpoint (backward compatibility)")

	// http.ListenAndServe starts the server. It will run forever until you stop it.
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Could not start server: %s\n", err)
	}
}
