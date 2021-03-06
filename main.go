package main

import (
	"fmt"
	"log"
	"net/http"
	//TODO: Add imports
	"./rest"
	"./crud"
)

func main() {
	http.HandleFunc("/health", health)
	//TODO: Add routes
	rest.RegisterEndpoints()
	crud.RegisterEndpoints()
	fmt.Println("Web server running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(200)
}
