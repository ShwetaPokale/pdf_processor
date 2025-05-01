package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func createTestContext(body []byte) (*gin.Context, *httptest.ResponseRecorder) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/login", bytes.NewBuffer(body))
	c.Request.Header.Set("Content-Type", "application/json")
	return c, w
}

func TestLogin_Success(t *testing.T) {
	credentials := map[string]string{
		"username": "admin",
		"password": "admin123",
	}
	jsonData, _ := json.Marshal(credentials)

	c, w := createTestContext(jsonData)
	Login(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]any
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Login successful", response["message"])
	assert.NotEmpty(t, response["token"])
}

func TestLogin_InvalidCredentials(t *testing.T) {
	credentials := map[string]string{
		"username": "wrong",
		"password": "wrong",
	}
	jsonData, _ := json.Marshal(credentials)

	c, w := createTestContext(jsonData)
	Login(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)

	var response map[string]any
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Invalid username or password", response["error"])
}

func TestLogin_InvalidRequestFormat(t *testing.T) {
	invalidData := map[string]string{
		"username": "admin",
	}
	jsonData, _ := json.Marshal(invalidData)

	c, w := createTestContext(jsonData)
	Login(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]any
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Invalid request format", response["error"])
}
