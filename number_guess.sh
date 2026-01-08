#!/bin/bash

# Variable para conectar a la base de datos
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# 1. Generar el número secreto
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# 2. Solicitar nombre de usuario
echo "Enter your username:"
read USERNAME

# 3. Buscar datos del usuario
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]
then
  # Usuario nuevo
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insertar nuevo usuario
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # Usuario existente
  echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# 4. Iniciar el juego
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0
ADIVINADO=false

until $ADIVINADO
do
  read USER_GUESS
  ((GUESS_COUNT++))

  # Validar que sea un número entero
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    # Lógica de comparación
    if [[ $USER_GUESS -eq $SECRET_NUMBER ]]
    then
      echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
      ADIVINADO=true
    elif [[ $USER_GUESS -gt $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  fi
done

# 5. Actualizar la base de datos al terminar
# Incrementar juegos jugados
UPDATE_GAMES=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE username='$USERNAME'")

# Verificar y actualizar el récord (best_game)
CURRENT_BEST=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")

if [[ -z $CURRENT_BEST || $GUESS_COUNT -lt $CURRENT_BEST ]]
then
  UPDATE_BEST=$($PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE username='$USERNAME'")
fi