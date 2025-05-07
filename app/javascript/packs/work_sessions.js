document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll(".right-buttons button").forEach((button) => {
      button.addEventListener("click", function (event) {
        event.preventDefault();
        let buttonElement = event.target;
        let url = buttonElement.getAttribute("formaction");
  
        fetch(url, {
          method: "POST",
          headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
        })
          .then((response) => response.json())
          .then((data) => {
            if (data.status === "clocked_in") {
              buttonElement.innerText = "Take a Break";
              buttonElement.className = "btn btn-warning";
            } else if (data.status === "on_break") {
              buttonElement.innerText = "Resume Work";
              buttonElement.className = "btn btn-primary";
            } else if (data.status === "resumed") {
              buttonElement.innerText = "Clock Out";
              buttonElement.className = "btn btn-danger";
            } else if (data.status === "clocked_out") {
              buttonElement.remove();
            }
  
            if (data.time) {
              document.getElementById("clock-in-time").innerText = data.time;
            }
          });
      });
    });
  });