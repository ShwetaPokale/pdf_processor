package handlers

import (
	"bytes"
	"encoding/json"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func createTestFileContext(filePath string, command string) (*gin.Context, *httptest.ResponseRecorder) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// Add file
	file, err := os.Open(filePath)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	part, err := writer.CreateFormFile("file", filepath.Base(filePath))
	if err != nil {
		panic(err)
	}
	_, err = part.Write([]byte("test content"))
	if err != nil {
		panic(err)
	}

	// Add command
	writer.WriteField("command", command)
	writer.Close()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/api/process", body)
	c.Request.Header.Set("Content-Type", writer.FormDataContentType())
	return c, w
}

func TestProcessFile_Success(t *testing.T) {
	// Create uploads directory if it doesn't exist
	if err := os.MkdirAll("uploads", 0755); err != nil {
		t.Fatalf("Failed to create uploads directory: %v", err)
	}

	// Create a test PDF file
	filePath := filepath.Join("uploads", "test.pdf")
	file, err := os.Create(filePath)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	file.Close()

	c, w := createTestFileContext(filePath, "show content")
	ProcessFile(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "File processed successfully", response["message"])
	assert.Contains(t, response, "response")

	// Clean up
	os.Remove(filePath)
}

func TestProcessFile_NoFile(t *testing.T) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	writer.WriteField("command", "show content")
	writer.Close()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/api/process", body)
	c.Request.Header.Set("Content-Type", writer.FormDataContentType())

	ProcessFile(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Contains(t, response["error"], "Error getting file")
}

func TestProcessFile_InvalidFileType(t *testing.T) {
	// Create uploads directory if it doesn't exist
	if err := os.MkdirAll("uploads", 0755); err != nil {
		t.Fatalf("Failed to create uploads directory: %v", err)
	}

	// Create a test file with invalid extension
	filePath := filepath.Join("uploads", "test.txt")
	file, err := os.Create(filePath)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	file.Close()

	c, w := createTestFileContext(filePath, "show content")
	ProcessFile(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Contains(t, response["error"], "Invalid file type")

	// Clean up
	os.Remove(filePath)
}
