select_interface() {
  # Get interface names from ifconfig command
  INTERFACES=$(ifconfig -s | awk '{print $1}')

  # Prompt user to select an interface
  echo "Select an interface:"
  select INTERFACE in $INTERFACES; do
    # Check if a valid option was selected
    if [ -n "$INTERFACE" ]; then
      echo "Selected interface: $INTERFACE"
      break
    else
      echo "Invalid selection. Please try again."
    fi
  done
}
select_interface
