package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"time"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		//randomize intended 500
		errorRate, _ := strconv.Atoi(r.Header.Get("X-Error"))
		rand.Seed(time.Now().UnixNano())
		errorNum := rand.Intn(10)
		if errorNum >= errorRate || errorRate == 0 {
			//get env
			var url = os.Getenv("REQUEST_URL")
			var serviceName = os.Getenv("SERVICE_NAME")

			//set url
			if url == "" {
				url = "https://openwhisk.ng.bluemix.net/api/v1/web/tenntenn_dev/default/helloGo.json?name=GCPUFukuoka"
			}

			//set service name
			if serviceName == "" {
				serviceName = "test-1"
			}

			//get body and return
			resp, err := http.Get(url)
			if err != nil {
				fmt.Fprintf(w, serviceName+" -> "+"StatusCodeError: 404")
			} else {
				defer resp.Body.Close()
				body, _ := ioutil.ReadAll(resp.Body)
				fmt.Fprintf(w, serviceName+" -> "+string(body))
			}
		} else {
			http.Error(w, "", http.StatusInternalServerError)
		}
	})

	http.ListenAndServe(":4000", nil)
}
